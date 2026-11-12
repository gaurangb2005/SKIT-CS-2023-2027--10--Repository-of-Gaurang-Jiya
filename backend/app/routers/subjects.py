from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.auth_utils import get_current_user, require_role
from app.db import get_db
from app.models import Content, Subject, User

router = APIRouter()


class SubjectCreate(BaseModel):
    name: str


@router.get("")
def list_subjects(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    subjects = db.query(Subject).all()
    results = []
    for s in subjects:
        count = db.query(Content).filter(Content.subject_id == s.id).count()
        results.append(
            {
                "id": s.id,
                "name": s.name,
                "content_count": count,
                "created_at": str(s.created_at),
            }
        )
    return results


@router.post("")
def create_subject(
    req: SubjectCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    name = req.name.strip()
    if not name:
        raise HTTPException(status_code=400, detail="Subject name cannot be empty")
    subject = Subject(name=name)
    db.add(subject)
    db.commit()
    db.refresh(subject)
    return {
        "id": subject.id,
        "name": subject.name,
        "content_count": 0,
        "created_at": str(subject.created_at),
    }


@router.delete("/{subject_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_subject(
    subject_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    subject = db.query(Subject).filter(Subject.id == subject_id).first()
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found")
    content_count = db.query(Content).filter(Content.subject_id == subject_id).count()
    if content_count > 0:
        raise HTTPException(status_code=400, detail="Cannot delete subject that still has content")
    db.delete(subject)
    db.commit()
    return None
