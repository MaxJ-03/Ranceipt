from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from sqlalchemy import Boolean, DateTime, ForeignKey, Numeric, Text, UniqueConstraint, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
	pass


class User(Base):
	__tablename__ = "users"

	id: Mapped[int] = mapped_column(primary_key=True)
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)


class AppSession(Base):
	__tablename__ = "app_sessions"

	id: Mapped[int] = mapped_column(primary_key=True)
	user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
	session_token_hash: Mapped[str] = mapped_column(Text, unique=True, index=True, nullable=False)
	expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
	revoked: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False, server_default="false")
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)


class OAuthState(Base):
	__tablename__ = "oauth_states"

	id: Mapped[int] = mapped_column(primary_key=True)
	state: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
	used: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False, server_default="false")
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)


class BunqConnection(Base):
	__tablename__ = "bunq_connections"

	id: Mapped[int] = mapped_column(primary_key=True)
	user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
	bunq_user_api_key_id: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
	encrypted_access_token: Mapped[str] = mapped_column(Text, nullable=False)
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
	last_synced_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class PersonalGoal(Base):
	__tablename__ = "personal_goals"

	id: Mapped[int] = mapped_column(primary_key=True)
	user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
	amount_to_save: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
	currency: Mapped[str] = mapped_column(Text, nullable=False, default="EUR", server_default="EUR")
	target_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)


class GeneralCategory(Base):
	__tablename__ = "general_categories"

	id: Mapped[int] = mapped_column(primary_key=True)
	name: Mapped[str] = mapped_column(Text, unique=True, nullable=False)


class CustomCategory(Base):
	__tablename__ = "custom_categories"

	id: Mapped[int] = mapped_column(primary_key=True)
	name: Mapped[str] = mapped_column(Text, unique=True, nullable=False)


class Transaction(Base):
	__tablename__ = "transactions"
	__table_args__ = (UniqueConstraint("user_id", "bunq_payment_id", name="uq_transactions_user_bunq_payment"),)

	id: Mapped[int] = mapped_column(primary_key=True)
	user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
	bunq_payment_id: Mapped[str] = mapped_column(Text, index=True, nullable=False)
	amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
	currency: Mapped[str] = mapped_column(Text, nullable=False, default="EUR", server_default="EUR")
	merchant: Mapped[str | None] = mapped_column(Text, nullable=True)
	description: Mapped[str | None] = mapped_column(Text, nullable=True)
	transaction_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True, nullable=False)
	general_category_id: Mapped[int | None] = mapped_column(
		ForeignKey("general_categories.id", ondelete="SET NULL"), index=True, nullable=True
	)
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)


class Receipt(Base):
	__tablename__ = "receipts"

	id: Mapped[int] = mapped_column(primary_key=True)
	user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
	transaction_id: Mapped[int | None] = mapped_column(
		ForeignKey("transactions.id", ondelete="SET NULL"), unique=True, index=True, nullable=True
	)
	merchant: Mapped[str | None] = mapped_column(Text, nullable=True)
	total_amount: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
	currency: Mapped[str] = mapped_column(Text, nullable=False, default="EUR", server_default="EUR")
	receipt_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)

	items: Mapped[list[ReceiptItem]] = relationship("ReceiptItem", back_populates="receipt", cascade="all, delete-orphan")


class ReceiptItem(Base):
	__tablename__ = "receipt_items"

	id: Mapped[int] = mapped_column(primary_key=True)
	receipt_id: Mapped[int] = mapped_column(ForeignKey("receipts.id", ondelete="CASCADE"), index=True, nullable=False)
	category_id: Mapped[int] = mapped_column(ForeignKey("custom_categories.id", ondelete="RESTRICT"), index=True, nullable=False)
	quantity: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False, default=Decimal("1"), server_default="1")
	unit_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
	created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)

	receipt: Mapped[Receipt] = relationship("Receipt", back_populates="items")
	category: Mapped[CustomCategory] = relationship("CustomCategory")
