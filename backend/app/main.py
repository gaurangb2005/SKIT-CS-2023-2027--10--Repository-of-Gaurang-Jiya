from contextlib import asynccontextmanager
import os

from fastapi import APIRouter, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.auth_utils import hash_password
from app.db import Base, SessionLocal, engine
from app.models import Attempt, Content, Question, Quiz, Subject, User
from app.routers import auth as auth_router
from app.routers import content as content_router
from app.routers import dashboard as dashboard_router
from app.routers import quizzes as quizzes_router
from app.routers import subjects as subjects_router
from app.routers import users as users_router

UPLOAD_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)


def seed_database():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        # Seed Admin
        admin = db.query(User).filter(User.email == "admin@example.com").first()
        if not admin:
            admin = User(
                name="Platform Admin",
                phone="+919999999999",
                email="admin@example.com",
                password_hash=hash_password("admin123"),
                role="admin",
                is_active=True,
            )
            db.add(admin)

        # Seed Teacher
        teacher = db.query(User).filter(User.email == "teacher@example.com").first()
        if not teacher:
            teacher = User(
                name="Pooja Sharma (Teacher)",
                phone="+919888888888",
                email="teacher@example.com",
                password_hash=hash_password("teacher123"),
                role="teacher",
                is_active=True,
                school="Government Secondary School",
            )
            db.add(teacher)

        # Seed Demo Student
        student = db.query(User).filter(User.phone == "+919876543210").first()
        if not student:
            student = User(
                name="Aarav Sharma",
                phone="+919876543210",
                email=None,
                role="student",
                is_active=True,
                grade="5",
                school="SKIT Model Rural School",
            )
            db.add(student)

        db.flush()

        # Seed Default Subjects
        subjects_data = ["Maths", "Science", "English", "Hindi"]
        existing_subjects = {s.name: s for s in db.query(Subject).all()}
        created_subjects = {}
        for s_name in subjects_data:
            if s_name not in existing_subjects:
                new_sub = Subject(name=s_name)
                db.add(new_sub)
                db.flush()
                created_subjects[s_name] = new_sub
            else:
                created_subjects[s_name] = existing_subjects[s_name]

        # Seed Sample Content for Maths
        maths_sub = created_subjects.get("Maths")
        if maths_sub and db.query(Content).filter(Content.subject_id == maths_sub.id).count() == 0:
            demo_content = Content(
                subject_id=maths_sub.id,
                title="Basic Fractions & Decimals",
                type="pdf",
                file_url="https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf",
                uploaded_by=teacher.id if teacher else 1,
            )
            db.add(demo_content)

        # Seed Sample Quiz for Maths
        if maths_sub and db.query(Quiz).filter(Quiz.subject_id == maths_sub.id).count() == 0:
            math_quiz = Quiz(
                subject_id=maths_sub.id,
                title="Fun with Fractions & Numbers",
                created_by=teacher.id if teacher else 1,
                published=True,
            )
            db.add(math_quiz)
            db.flush()

            questions = [
                Question(
                    quiz_id=math_quiz.id,
                    text="What is 1/2 + 1/2 equal to?",
                    options=["1/4", "1", "2", "1/2"],
                    correct_option=1,
                ),
                Question(
                    quiz_id=math_quiz.id,
                    text="Which number is the largest?",
                    options=["0.25", "0.5", "0.75", "0.1"],
                    correct_option=2,
                ),
                Question(
                    quiz_id=math_quiz.id,
                    text="How many halves make a whole?",
                    options=["1", "2", "3", "4"],
                    correct_option=1,
                ),
            ]
            db.add_all(questions)

        db.commit()
    except Exception as e:
        db.rollback()
        print(f"Error seeding database: {e}")
    finally:
        db.close()


@asynccontextmanager
async def lifespan(app: FastAPI):
    seed_database()
    yield


app = FastAPI(title="Rural Edu Platform API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")


@app.get("/health")
def health():
    return {"status": "ok", "app": "Rural Edu Platform"}


api_router = APIRouter(prefix="/api/v1")
api_router.include_router(auth_router.router, prefix="/auth", tags=["auth"])
api_router.include_router(users_router.router, prefix="/users", tags=["users"])
api_router.include_router(subjects_router.router, prefix="/subjects", tags=["subjects"])
api_router.include_router(content_router.router, prefix="/content", tags=["content"])
api_router.include_router(dashboard_router.router, prefix="/dashboard", tags=["dashboard"])
api_router.include_router(quizzes_router.router, prefix="/quizzes", tags=["quizzes"])

app.include_router(api_router)
