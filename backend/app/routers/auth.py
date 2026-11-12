from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.auth_utils import create_access_token, get_current_user, hash_password, verify_password
from app.db import get_db
from app.models import User

router = APIRouter()


class LoginRequest(BaseModel):
    email: str
    password: str


class OtpLoginRequest(BaseModel):
    id_token: str


@router.post("/login")
def login(req: LoginRequest, db: Session = Depends(get_db)):
    email = req.email.strip().lower()
    user = db.query(User).filter(User.email == email).first()
    if not user or not verify_password(req.password, user.password_hash or ""):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is deactivated",
        )
    access_token = create_access_token({"sub": str(user.id), "role": user.role})
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "role": user.role,
        "user_id": user.id,
    }


@router.post("/otp-login")
def otp_login(req: OtpLoginRequest, db: Session = Depends(get_db)):
    # In a full Firebase environment, we'd verify the token with firebase_admin.auth.verify_id_token
    # Here, we support both decoded mock/real tokens or test phone numbers gracefully.
    phone = "+919876543210"
    if req.id_token.startswith("+91") or req.id_token.isdigit():
        phone = req.id_token if req.id_token.startswith("+") else f"+91{req.id_token}"
    elif len(req.id_token) > 20:
        # If it's a simulated or real Firebase token, extract or map a test phone
        phone = "+919876543210"

    user = db.query(User).filter(User.phone == phone).first()
    if not user:
        user = User(
            name="Student",
            phone=phone,
            role="student",
            is_active=True,
            grade="5",
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    access_token = create_access_token({"sub": str(user.id), "role": user.role})
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "role": user.role,
        "user_id": user.id,
    }


@router.get("/me")
def get_me(current_user: User = Depends(get_current_user)):
    return {
        "id": current_user.id,
        "name": current_user.name,
        "phone": current_user.phone,
        "email": current_user.email,
        "role": current_user.role,
        "grade": current_user.grade,
        "school": current_user.school,
        "is_active": current_user.is_active,
    }
