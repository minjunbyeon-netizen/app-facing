from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from zoneinfo import ZoneInfo
from .database import Base

KST = ZoneInfo("Asia/Seoul")

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    nickname = Column(String, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(KST))
    records = relationship("RehabRecord", back_populates="user")

class RehabRecord(Base):
    __tablename__ = "rehab_records"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    movement_id = Column(String, nullable=False)
    pain_site_id = Column(String, nullable=False)
    cause_id = Column(String, nullable=False)
    stage_index = Column(Integer, default=0)
    note = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(KST))
    updated_at = Column(DateTime, default=lambda: datetime.now(KST), onupdate=lambda: datetime.now(KST))
    user = relationship("User", back_populates="records")
