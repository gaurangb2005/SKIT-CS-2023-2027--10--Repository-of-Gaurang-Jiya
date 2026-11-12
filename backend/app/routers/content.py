import os
import uuid
from fastapi import APIRouter, Depends, Form, HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from app.auth_utils import get_current_user, require_role
from app.db import get_db
from app.models import Content, User

router = APIRouter()

UPLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "..", "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)


@router.get("")
def list_content(
    subject_id: int | None = None,
    limit: int = 100,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    query = db.query(Content)
    if subject_id is not None:
        query = query.filter(Content.subject_id == subject_id)
    contents = query.order_by(Content.id.desc()).limit(limit).all()
    return [
        {
            "id": c.id,
            "subject_id": c.subject_id,
            "title": c.title,
            "type": c.type,
            "file_url": c.file_url,
            "uploaded_by": c.uploaded_by,
            "updated_at": str(c.updated_at),
        }
        for c in contents
    ]


@router.post("")
async def create_content(
    title: str = Form(...),
    subject_id: int = Form(...),
    type: str = Form(...),
    file: UploadFile | None = None,
    file_url: str | None = Form(None),
    db: Session = Depends(get_db),
    user: User = Depends(require_role("teacher", "admin")),
):
    resolved_file_url = file_url or ""
    if file and file.filename:
        safe_filename = f"{uuid.uuid4().hex}_{file.filename}"
        dest_path = os.path.join(UPLOAD_DIR, safe_filename)
        contents = await file.read()
        with open(dest_path, "wb") as f:
            f.write(contents)
        resolved_file_url = f"/uploads/{safe_filename}"

    content = Content(
        subject_id=subject_id,
        title=title,
        type=type.lower(),
        file_url=resolved_file_url,
        uploaded_by=user.id,
    )
    db.add(content)
    db.commit()
    db.refresh(content)
    return {
        "id": content.id,
        "subject_id": content.subject_id,
        "title": content.title,
        "type": content.type,
        "file_url": content.file_url,
        "uploaded_by": content.uploaded_by,
        "updated_at": str(content.updated_at),
    }
