import os
import httpx
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from ..database import get_db
from ..models import User
from ..auth import hash_password, verify_password, create_access_token

router = APIRouter(prefix="/auth", tags=["auth"])

NAVER_REDIRECT_URI = "https://web-production-28002.up.railway.app/auth/naver/callback"
FRONTEND_URL = "https://rimseorim.github.io/rahap1"

class SignupRequest(BaseModel):
    email: EmailStr
    password: str
    nickname: str

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

@router.post("/signup")
def signup(req: SignupRequest, db: Session = Depends(get_db)):
    if db.query(User).filter(User.email == req.email).first():
        raise HTTPException(status_code=400, detail="이미 사용 중인 이메일입니다.")
    user = User(email=req.email, hashed_password=hash_password(req.password), nickname=req.nickname)
    db.add(user)
    db.commit()
    db.refresh(user)
    return {"token": create_access_token(user.id, user.email), "nickname": user.nickname}

@router.post("/login")
def login(req: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == req.email).first()
    if not user or not user.hashed_password or not verify_password(req.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="이메일 또는 비밀번호가 올바르지 않습니다.")
    return {"token": create_access_token(user.id, user.email), "nickname": user.nickname}


@router.get("/naver/login")
def naver_login():
    client_id = os.getenv("NAVER_CLIENT_ID", "")
    if not client_id:
        raise HTTPException(status_code=500, detail="네이버 Client ID가 설정되지 않았습니다.")
    url = (
        "https://nid.naver.com/oauth2.0/authorize"
        f"?response_type=code&client_id={client_id}"
        f"&redirect_uri={NAVER_REDIRECT_URI}&state=crossfit_rehab"
    )
    return RedirectResponse(url)


@router.get("/naver/callback")
async def naver_callback(code: str, state: str, db: Session = Depends(get_db)):
    client_id = os.getenv("NAVER_CLIENT_ID", "")
    client_secret = os.getenv("NAVER_CLIENT_SECRET", "")
    async with httpx.AsyncClient() as client:
        token_res = await client.post(
            "https://nid.naver.com/oauth2.0/token",
            params={
                "grant_type": "authorization_code",
                "client_id": client_id,
                "client_secret": client_secret,
                "code": code,
                "state": state,
            },
        )
        token_data = token_res.json()
        access_token = token_data.get("access_token")
        if not access_token:
            return RedirectResponse(f"{FRONTEND_URL}?error=naver_token_failed")

        # 2. 사용자 정보 조회
        profile_res = await client.get(
            "https://openapi.naver.com/v1/nid/me",
            headers={"Authorization": f"Bearer {access_token}"},
        )
        profile = profile_res.json().get("response", {})

    email = profile.get("email")
    nickname = profile.get("nickname") or profile.get("name") or "네이버유저"
    if not email:
        return RedirectResponse(f"{FRONTEND_URL}?error=naver_no_email")

    # 3. 유저 조회 or 생성
    user = db.query(User).filter(User.email == email).first()
    if not user:
        user = User(email=email, hashed_password="", nickname=nickname)
        db.add(user)
        db.commit()
        db.refresh(user)

    jwt_token = create_access_token(user.id, user.email)
    return RedirectResponse(f"{FRONTEND_URL}?naver_token={jwt_token}&naver_nickname={user.nickname}")
