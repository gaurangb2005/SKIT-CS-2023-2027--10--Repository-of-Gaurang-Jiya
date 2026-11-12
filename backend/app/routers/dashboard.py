from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth_utils import get_current_user, require_role
from app.db import get_db
from app.models import Attempt, Content, Quiz, Subject, User

router = APIRouter()


@router.get("/student")
def student_dashboard(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    subjects = db.query(Subject).all()
    subject_list = []
    for s in subjects:
        c_count = db.query(Content).filter(Content.subject_id == s.id).count()
        subject_list.append({
            "id": s.id,
            "name": s.name,
            "content_count": c_count,
        })

    recent_content = db.query(Content).order_by(Content.id.desc()).limit(10).all()
    recent_list = [
        {
            "id": c.id,
            "subject_id": c.subject_id,
            "title": c.title,
            "type": c.type,
            "file_url": c.file_url,
        }
        for c in recent_content
    ]

    return {
        "subjects": subject_list,
        "recent_content": recent_list,
    }


@router.get("/admin")
def admin_dashboard(
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    total_students = db.query(User).filter(User.role == "student").count()
    total_teachers = db.query(User).filter(User.role == "teacher").count()
    total_subjects = db.query(Subject).count()
    total_content = db.query(Content).count()
    total_quizzes = db.query(Quiz).count()
    total_attempts = db.query(Attempt).count()

    return {
        "students": total_students,
        "teachers": total_teachers,
        "subjects": total_subjects,
        "content": total_content,
        "quizzes": total_quizzes,
        "attempts": total_attempts,
    }
