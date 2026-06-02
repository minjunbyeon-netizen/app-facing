from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime, timezone
from jose import JWTError
from ..database import get_db
from ..models import RehabRecord, User
from ..auth import decode_token

router = APIRouter(prefix="/records", tags=["records"])

DEMO_EMAIL = "demo@rehab.com"

def get_current_user(token: str, db: Session) -> User:
    if token == "demo":
        user = db.query(User).filter(User.email == DEMO_EMAIL).first()
        if not user:
            user = User(email=DEMO_EMAIL, hashed_password="demo", nickname="데모유저")
            db.add(user)
            db.commit()
            db.refresh(user)
        return user
    try:
        payload = decode_token(token)
        user = db.query(User).filter(User.id == int(payload["sub"])).first()
        if not user:
            raise HTTPException(status_code=401, detail="유효하지 않은 토큰입니다.")
        return user
    except JWTError:
        raise HTTPException(status_code=401, detail="유효하지 않은 토큰입니다.")

class RecordUpsert(BaseModel):
    token: str
    movement_id: str
    pain_site_id: str
    cause_id: str
    stage_index: int = 0

class RecordDelete(BaseModel):
    token: str
    record_id: int

@router.post("/save")
def save_record(req: RecordUpsert, db: Session = Depends(get_db)):
    user = get_current_user(req.token, db)
    record = db.query(RehabRecord).filter(
        RehabRecord.user_id == user.id,
        RehabRecord.movement_id == req.movement_id,
        RehabRecord.pain_site_id == req.pain_site_id,
    ).first()
    if record:
        record.cause_id = req.cause_id
        record.stage_index = req.stage_index
        record.updated_at = datetime.now(timezone.utc)
    else:
        record = RehabRecord(
            user_id=user.id,
            movement_id=req.movement_id,
            pain_site_id=req.pain_site_id,
            cause_id=req.cause_id,
            stage_index=req.stage_index,
        )
        db.add(record)
    db.commit()
    db.refresh(record)
    return {"id": record.id, "cause_id": record.cause_id, "stage_index": record.stage_index}

@router.get("/mine")
def get_my_records(token: str, db: Session = Depends(get_db)):
    user = get_current_user(token, db)
    records = db.query(RehabRecord).filter(RehabRecord.user_id == user.id).all()
    return [
        {
            "id": r.id,
            "movement_id": r.movement_id,
            "pain_site_id": r.pain_site_id,
            "cause_id": r.cause_id,
            "stage_index": r.stage_index,
            "updated_at": r.updated_at.isoformat(),
        }
        for r in records
    ]

@router.post("/delete")
def delete_record(req: RecordDelete, db: Session = Depends(get_db)):
    user = get_current_user(req.token, db)
    record = db.query(RehabRecord).filter(
        RehabRecord.id == req.record_id,
        RehabRecord.user_id == user.id
    ).first()
    if not record:
        raise HTTPException(status_code=404, detail="기록을 찾을 수 없습니다.")
    db.delete(record)
    db.commit()
    return {"ok": True}
