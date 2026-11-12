from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.auth_utils import get_current_user, require_role
from app.db import get_db
from app.models import User

router = APIRouter()


class UpdateProfileRequest(BaseModel):
    name: str | None = None
    grade: str | None = None
    school: str | None = None


@router.get("")
def list_users(
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    users = db.query(User).order_by(User.id.desc()).all()
    return [
        {
            "id": u.id,
            "name": u.name,
            "phone": u.phone,
            "email": u.email,
            "role": u.role,
            "grade": u.grade,
            "school": u.school,
            "is_active": u.is_active,
            "created_at": str(u.created_at),
        }
        for u in users
    ]


@router.get("/me")
def get_current_user_profile(user: User = Depends(get_current_user)):
    return {
        "id": user.id,
        "name": user.name,
        "phone": user.phone,
        "email": user.email,
        "role": user.role,
        "grade": user.grade,
        "school": user.school,
        "is_active": user.is_active,
    }


@router.patch("/me")
def update_current_user_profile(
    req: UpdateProfileRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if req.name is not None:
        user.name = req.name
    if req.grade is not None:
        user.grade = req.grade
    if req.school is not None:
        user.school = req.school
    db.commit()
    db.refresh(user)
    return {
        "id": user.id,
        "name": user.name,
        "phone": user.phone,
        "email": user.email,
        "role": user.role,
        "grade": user.grade,
        "school": user.school,
        "is_active": user.is_active,
    }


@router.patch("/{user_id}/active")
def toggle_user_active(
    user_id: int,
    is_active: bool,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = is_active
    db.commit()
    db.refresh(user)
    return {
        "id": user.id,
        "name": user.name,
        "is_active": user.is_active,
        "role": user.role,
    }
