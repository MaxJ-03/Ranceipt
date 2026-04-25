from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy.orm import Session

from app.database import get_db
from app.receipts.repository import ReceiptRepository
from app.receipts.schemas import ReceiptParseResponse
from app.receipts.service import ReceiptPipeline


router = APIRouter(prefix="/receipts", tags=["receipts"])
pipeline = ReceiptPipeline()
repository = ReceiptRepository()


@router.post("/parse-only", response_model=ReceiptParseResponse)
async def parse_receipt(
	image: UploadFile = File(...),
) -> ReceiptParseResponse:
	"""Parse a receipt image without saving to database."""
	image_bytes = await image.read()
	parsed = pipeline.parse(image_bytes=image_bytes, filename=image.filename, content_type=image.content_type)
	return parsed


@router.post("/parse", response_model=ReceiptParseResponse)
async def parse_and_save_receipt(
	image: UploadFile = File(...),
	user_id: int = Form(...),
	transaction_id: int | None = Form(default=None),
	db: Session = Depends(get_db),
) -> ReceiptParseResponse:
	image_bytes = await image.read()
	parsed = pipeline.parse(image_bytes=image_bytes, filename=image.filename, content_type=image.content_type)
	saved = repository.save_parsed_receipt(
		db,
		user_id=user_id,
		transaction_id=transaction_id,
		parsed_receipt=parsed,
	)
	return parsed.model_copy(update={"receipt_id": saved.id})


@router.get("/{receipt_id}", response_model=ReceiptParseResponse)
def get_saved_receipt(receipt_id: int, db: Session = Depends(get_db)) -> ReceiptParseResponse:
	receipt = repository.get_parsed_receipt_by_id(db, receipt_id)
	if receipt is None:
		raise HTTPException(status_code=404, detail="Receipt not found")
	return receipt
