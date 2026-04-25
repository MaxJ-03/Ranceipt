from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import get_db
from app.receipts.repository import ReceiptRepository
from app.receipts.schemas import ReceiptParseResponse
from app.receipts.service import ReceiptPipeline


router = APIRouter(prefix="/receipts", tags=["receipts"])

pipeline = ReceiptPipeline()
repository = ReceiptRepository()


class ReceiptItemCreate(BaseModel):
	category_id: int
	quantity: float = 1
	unit_price: float


class ReceiptCreate(BaseModel):
	transaction_id: Optional[int] = None
	merchant: Optional[str] = None
	total_amount: Optional[float] = None
	currency: str = "EUR"
	receipt_date: Optional[datetime] = None
	items: list[ReceiptItemCreate] = Field(default_factory=list)


def rows_to_dicts(rows):
	return [dict(row._mapping) for row in rows]


def find_best_transaction_id(
	db: Session,
	*,
	user_id: int,
	receipt_total: float,
	receipt_date: datetime,
	merchant: str | None,
	currency: str,
) -> int | None:
	"""Find best matching transaction by amount, timestamp proximity, and merchant similarity."""
	match = db.execute(
		text(
			"""
			SELECT
				t.id,
				ABS(ABS(t.amount) - :total_amount) AS amount_difference,
				ABS(EXTRACT(EPOCH FROM (t.transaction_date - CAST(:receipt_date AS timestamptz)))) AS date_difference_seconds,
				CASE
					WHEN :merchant IS NULL THEN 0
					WHEN LOWER(COALESCE(t.merchant, '')) = LOWER(:merchant) THEN 0
					WHEN LOWER(COALESCE(t.merchant, '')) LIKE LOWER(:merchant_like)
						OR LOWER(COALESCE(t.description, '')) LIKE LOWER(:merchant_like)
					THEN 1
					ELSE 2
				END AS merchant_rank
			FROM transactions t
			LEFT JOIN receipts r
				ON r.transaction_id = t.id
			WHERE t.user_id = :user_id
			  AND r.id IS NULL
			  AND t.currency = :currency
			  AND ABS(ABS(t.amount) - :total_amount) <= 1.00
			  AND ABS(EXTRACT(EPOCH FROM (t.transaction_date - CAST(:receipt_date AS timestamptz)))) <= 172800
			ORDER BY merchant_rank ASC, amount_difference ASC, date_difference_seconds ASC
			LIMIT 1;
			"""
		),
		{
			"user_id": user_id,
			"total_amount": receipt_total,
			"receipt_date": receipt_date,
			"merchant": merchant,
			"merchant_like": f"%{merchant}%" if merchant else None,
			"currency": currency,
		},
	).mappings().first()

	if not match:
		return None

	return int(match["id"])


@router.post("/parse-only", response_model=ReceiptParseResponse)
async def parse_receipt(
	image: UploadFile = File(...),
) -> ReceiptParseResponse:
	"""Parse a receipt image without saving to database."""
	image_bytes = await image.read()
	parsed = pipeline.parse(
		image_bytes=image_bytes,
		filename=image.filename,
		content_type=image.content_type,
	)
	return parsed


@router.post("/parse", response_model=ReceiptParseResponse)
async def parse_and_save_receipt(
	image: UploadFile = File(...),
	user_id: int = Form(...),
	transaction_id: int | None = Form(default=None),
	db: Session = Depends(get_db),
) -> ReceiptParseResponse:
	"""
	Person 2 endpoint:
	AI parses receipt image, then saves parsed receipt to database.
	"""
	image_bytes = await image.read()

	parsed = pipeline.parse(
		image_bytes=image_bytes,
		filename=image.filename,
		content_type=image.content_type,
	)

	resolved_transaction_id = transaction_id
	if resolved_transaction_id is None:
		resolved_transaction_id = find_best_transaction_id(
			db,
			user_id=user_id,
			receipt_total=parsed.receipt_total,
			receipt_date=parsed.timestamp,
			merchant=parsed.merchant,
			currency=parsed.currency,
		)

	saved = repository.save_parsed_receipt(
		db,
		user_id=user_id,
		transaction_id=resolved_transaction_id,
		parsed_receipt=parsed,
	)

	db.commit()

	return parsed.model_copy(update={"receipt_id": saved.id})


@router.post("/")
def create_receipt(
	body: ReceiptCreate,
	db: Session = Depends(get_db),
):
	"""
	Manual/database endpoint:
	Stores already-parsed receipt JSON into receipts + receipt_items.

	This is what the AI pipeline can call after parsing if needed.
	"""
	if body.transaction_id is not None:
		transaction = db.execute(
			text(
				"""
				SELECT id
				FROM transactions
				WHERE id = :transaction_id
				LIMIT 1;
				"""
			),
			{"transaction_id": body.transaction_id},
		).mappings().first()

		if not transaction:
			raise HTTPException(status_code=404, detail="Transaction not found")

	try:
		receipt = db.execute(
			text(
				"""
				INSERT INTO receipts (
					user_id,
					transaction_id,
					merchant,
					total_amount,
					currency,
					receipt_date
				)
				VALUES (
					:user_id,
					:transaction_id,
					:merchant,
					:total_amount,
					:currency,
					:receipt_date
				)
				RETURNING id, user_id, transaction_id, merchant, total_amount, currency, receipt_date, created_at;
				"""
			),
			{
				"user_id": 1,  # temporary until this endpoint uses auth/session
				"transaction_id": body.transaction_id,
				"merchant": body.merchant,
				"total_amount": body.total_amount,
				"currency": body.currency,
				"receipt_date": body.receipt_date,
			},
		).mappings().first()

		for item in body.items:
			db.execute(
				text(
					"""
					INSERT INTO receipt_items (
						receipt_id,
						category_id,
						quantity,
						unit_price
					)
					VALUES (
						:receipt_id,
						:category_id,
						:quantity,
						:unit_price
					);
					"""
				),
				{
					"receipt_id": receipt["id"],
					"category_id": item.category_id,
					"quantity": item.quantity,
					"unit_price": item.unit_price,
				},
			)

		db.commit()
		return dict(receipt)

	except Exception as e:
		db.rollback()
		raise HTTPException(status_code=500, detail=str(e))


@router.get("/")
def get_receipts(
	db: Session = Depends(get_db),
):
	rows = db.execute(
		text(
			"""
			SELECT
				r.id,
				r.user_id,
				r.transaction_id,
				r.merchant,
				r.total_amount,
				r.currency,
				r.receipt_date,
				r.created_at,
				COUNT(ri.id) AS item_count,
				COALESCE(SUM(ri.quantity * ri.unit_price), 0) AS items_total
			FROM receipts r
			LEFT JOIN receipt_items ri
				ON ri.receipt_id = r.id
			GROUP BY r.id
			ORDER BY r.created_at DESC;
			"""
		)
	).all()

	return rows_to_dicts(rows)


@router.get("/match/candidates")
def find_receipt_transaction_candidates(
	total_amount: float = Query(...),
	receipt_date: Optional[datetime] = Query(default=None),
	merchant: Optional[str] = Query(default=None),
	db: Session = Depends(get_db),
):
	rows = db.execute(
		text(
			"""
			SELECT
				t.id,
				t.bunq_payment_id,
				t.amount,
				t.currency,
				t.merchant,
				t.description,
				t.transaction_date,
				gc.name AS general_category,
				ABS(ABS(t.amount) - :total_amount) AS amount_difference
			FROM transactions t
			LEFT JOIN general_categories gc
				ON gc.id = t.general_category_id
			WHERE ABS(ABS(t.amount) - :total_amount) <= 0.50
			  AND (
					:receipt_date IS NULL
					OR ABS(EXTRACT(EPOCH FROM (t.transaction_date - CAST(:receipt_date AS timestamptz)))) <= 172800
				  )
			  AND (
					:merchant IS NULL
					OR LOWER(COALESCE(t.merchant, '')) LIKE LOWER(:merchant_like)
					OR LOWER(COALESCE(t.description, '')) LIKE LOWER(:merchant_like)
				  )
			ORDER BY amount_difference ASC, t.transaction_date DESC
			LIMIT 10;
			"""
		),
		{
			"total_amount": total_amount,
			"receipt_date": receipt_date,
			"merchant": merchant,
			"merchant_like": f"%{merchant}%" if merchant else None,
		},
	).all()

	return rows_to_dicts(rows)


@router.get("/{receipt_id}", response_model=ReceiptParseResponse)
def get_saved_receipt(
	receipt_id: int,
	db: Session = Depends(get_db),
) -> ReceiptParseResponse:
	"""
	Person 2 endpoint:
	Returns saved parsed receipt using their repository format.
	"""
	receipt = repository.get_parsed_receipt_by_id(db, receipt_id)

	if receipt is None:
		raise HTTPException(status_code=404, detail="Receipt not found")

	return receipt


@router.get("/{receipt_id}/detail")
def get_receipt_detail(
	receipt_id: int,
	db: Session = Depends(get_db),
):
	receipt = db.execute(
		text(
			"""
			SELECT
				id,
				user_id,
				transaction_id,
				merchant,
				total_amount,
				currency,
				receipt_date,
				created_at
			FROM receipts
			WHERE id = :receipt_id
			LIMIT 1;
			"""
		),
		{"receipt_id": receipt_id},
	).mappings().first()

	if not receipt:
		raise HTTPException(status_code=404, detail="Receipt not found")

	items = db.execute(
		text(
			"""
			SELECT
				ri.id,
				ri.receipt_id,
				ri.category_id,
				cc.name AS category,
				ri.quantity,
				ri.unit_price,
				ri.created_at
			FROM receipt_items ri
			JOIN custom_categories cc
				ON cc.id = ri.category_id
			WHERE ri.receipt_id = :receipt_id
			ORDER BY ri.id ASC;
			"""
		),
		{"receipt_id": receipt_id},
	).all()

	return {
		"receipt": dict(receipt),
		"items": rows_to_dicts(items),
	}


@router.post("/{receipt_id}/link-transaction/{transaction_id}")
def link_receipt_to_transaction(
	receipt_id: int,
	transaction_id: int,
	db: Session = Depends(get_db),
):
	receipt = db.execute(
		text(
			"""
			SELECT id
			FROM receipts
			WHERE id = :receipt_id
			LIMIT 1;
			"""
		),
		{"receipt_id": receipt_id},
	).mappings().first()

	if not receipt:
		raise HTTPException(status_code=404, detail="Receipt not found")

	transaction = db.execute(
		text(
			"""
			SELECT id
			FROM transactions
			WHERE id = :transaction_id
			LIMIT 1;
			"""
		),
		{"transaction_id": transaction_id},
	).mappings().first()

	if not transaction:
		raise HTTPException(status_code=404, detail="Transaction not found")

	updated = db.execute(
		text(
			"""
			UPDATE receipts
			SET transaction_id = :transaction_id
			WHERE id = :receipt_id
			RETURNING id, transaction_id;
			"""
		),
		{
			"transaction_id": transaction_id,
			"receipt_id": receipt_id,
		},
	).mappings().first()

	db.commit()

	return {
		"message": "Receipt linked to transaction",
		"receipt_id": updated["id"],
		"transaction_id": updated["transaction_id"],
	}


@router.delete("/{receipt_id}/unlink-transaction")
def unlink_receipt_from_transaction(
	receipt_id: int,
	db: Session = Depends(get_db),
):
	updated = db.execute(
		text(
			"""
			UPDATE receipts
			SET transaction_id = NULL
			WHERE id = :receipt_id
			RETURNING id;
			"""
		),
		{"receipt_id": receipt_id},
	).mappings().first()

	db.commit()

	if not updated:
		raise HTTPException(status_code=404, detail="Receipt not found")

	return {
		"message": "Receipt unlinked from transaction",
		"receipt_id": updated["id"],
	}


@router.delete("/{receipt_id}")
def delete_receipt(
	receipt_id: int,
	db: Session = Depends(get_db),
):
	deleted = db.execute(
		text(
			"""
			DELETE FROM receipts
			WHERE id = :receipt_id
			RETURNING id;
			"""
		),
		{"receipt_id": receipt_id},
	).mappings().first()

	db.commit()

	if not deleted:
		raise HTTPException(status_code=404, detail="Receipt not found")

	return {"deleted_receipt_id": deleted["id"]}