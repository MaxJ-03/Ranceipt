from fastapi import APIRouter, File, UploadFile

from app.receipts.schemas import ReceiptParseResponse
from app.receipts.service import ReceiptPipeline


router = APIRouter(prefix="/receipts", tags=["receipts"])
pipeline = ReceiptPipeline()


@router.post("/parse", response_model=ReceiptParseResponse)
async def parse_receipt(image: UploadFile = File(...)) -> ReceiptParseResponse:
	image_bytes = await image.read()
	return pipeline.parse(image_bytes=image_bytes, filename=image.filename, content_type=image.content_type)
