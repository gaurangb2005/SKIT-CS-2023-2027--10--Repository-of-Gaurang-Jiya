from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.auth_utils import get_current_user, require_role
from app.db import get_db
from app.models import Attempt, Question, Quiz, Subject, User

router = APIRouter()


class QuestionCreate(BaseModel):
    text: str
    options: list[str]
    correct_option: int


class QuizCreate(BaseModel):
    subject_id: int
    title: str
    questions: list[QuestionCreate]


class QuizSubmit(BaseModel):
    answers: list[int]


@router.get("")
def list_quizzes(
    subject_id: int | None = None,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    query = db.query(Quiz)
    if subject_id is not None:
        query = query.filter(Quiz.subject_id == subject_id)

    # Students only see published quizzes; teachers and admins see all
    if user.role == "student":
        query = query.filter(Quiz.published == True)

    quizzes = query.order_by(Quiz.id.desc()).all()
    results = []
    for q in quizzes:
        q_count = len(q.questions)
        best_attempt = None
        if user.role == "student":
            best = (
                db.query(Attempt)
                .filter(Attempt.quiz_id == q.id, Attempt.student_id == user.id)
                .order_by(Attempt.score.desc())
                .first()
            )
            if best:
                best_attempt = {"score": best.score, "total": best.total}

        results.append(
            {
                "id": q.id,
                "subject_id": q.subject_id,
                "title": q.title,
                "published": q.published,
                "question_count": q_count,
                "best_attempt": best_attempt,
                "updated_at": str(q.updated_at),
            }
        )
    return results


@router.get("/history/me")
def my_attempt_history(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    attempts = (
        db.query(Attempt)
        .filter(Attempt.student_id == user.id)
        .order_by(Attempt.created_at.desc())
        .all()
    )
    results = []
    for a in attempts:
        quiz = db.query(Quiz).filter(Quiz.id == a.quiz_id).first()
        results.append(
            {
                "id": a.id,
                "quiz_id": a.quiz_id,
                "quiz_title": quiz.title if quiz else "Quiz",
                "score": a.score,
                "total": a.total,
                "xp_earned": a.xp_earned,
                "created_at": str(a.created_at),
            }
        )
    return results


@router.get("/{quiz_id}")
def get_quiz_detail(
    quiz_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    quiz = db.query(Quiz).filter(Quiz.id == quiz_id).first()
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")

    questions_data = [
        {
            "id": q.id,
            "text": q.text,
            "options": q.options,
            "correct_option": q.correct_option if user.role != "student" else None,
        }
        for q in quiz.questions
    ]
    return {
        "id": quiz.id,
        "subject_id": quiz.subject_id,
        "title": quiz.title,
        "published": quiz.published,
        "questions": questions_data,
    }


@router.post("")
def create_quiz(
    req: QuizCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_role("teacher", "admin")),
):
    quiz = Quiz(
        subject_id=req.subject_id,
        title=req.title,
        created_by=user.id,
        published=False,
    )
    db.add(quiz)
    db.flush()

    for q in req.questions:
        question = Question(
            quiz_id=quiz.id,
            text=q.text,
            options=q.options,
            correct_option=q.correct_option,
        )
        db.add(question)

    db.commit()
    db.refresh(quiz)
    return {
        "id": quiz.id,
        "subject_id": quiz.subject_id,
        "title": quiz.title,
        "published": quiz.published,
        "question_count": len(quiz.questions),
    }


@router.post("/{quiz_id}/submit")
def submit_quiz_attempt(
    quiz_id: int,
    req: QuizSubmit,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    quiz = db.query(Quiz).filter(Quiz.id == quiz_id).first()
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")

    questions = quiz.questions
    total = len(questions)
    if total == 0:
        raise HTTPException(status_code=400, detail="Quiz has no questions")

    score = 0
    detailed_results = []
    for i, q in enumerate(questions):
        user_answer = req.answers[i] if i < len(req.answers) else -1
        is_correct = user_answer == q.correct_option
        if is_correct:
            score += 1
        detailed_results.append(
            {
                "text": q.text,
                "options": q.options,
                "selected": user_answer,
                "correct_option": q.correct_option,
            }
        )

    percentage = round((score / total) * 100, 1)
    xp_earned = score * 20  # 20 XP per correct question

    attempt = Attempt(
        student_id=user.id,
        quiz_id=quiz.id,
        score=score,
        total=total,
        xp_earned=xp_earned,
        answers=req.answers,
    )
    db.add(attempt)
    db.commit()

    return {
        "score": score,
        "total": total,
        "percentage": percentage,
        "xp_earned": xp_earned,
        "results": detailed_results,
    }


@router.get("/{quiz_id}/attempts")
def get_quiz_attempts(
    quiz_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_role("teacher", "admin")),
):
    attempts = (
        db.query(Attempt)
        .filter(Attempt.quiz_id == quiz_id)
        .order_by(Attempt.created_at.desc())
        .all()
    )
    results = []
    for a in attempts:
        student = db.query(User).filter(User.id == a.student_id).first()
        results.append(
            {
                "id": a.id,
                "student_name": student.name if student else "Student",
                "score": a.score,
                "total": a.total,
                "xp_earned": a.xp_earned,
                "created_at": str(a.created_at),
            }
        )
    return results


@router.patch("/{quiz_id}/publish")
def toggle_publish_quiz(
    quiz_id: int,
    published: bool,
    db: Session = Depends(get_db),
    user: User = Depends(require_role("teacher", "admin")),
):
    quiz = db.query(Quiz).filter(Quiz.id == quiz_id).first()
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")
    quiz.published = published
    db.commit()
    db.refresh(quiz)
    return {
        "id": quiz.id,
        "published": quiz.published,
    }


@router.delete("/{quiz_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_quiz(
    quiz_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_role("teacher", "admin")),
):
    quiz = db.query(Quiz).filter(Quiz.id == quiz_id).first()
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")
    db.delete(quiz)
    db.commit()
    return None
