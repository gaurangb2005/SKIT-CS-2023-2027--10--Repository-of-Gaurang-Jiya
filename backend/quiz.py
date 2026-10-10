import os

from fastapi import APIRouter, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.routers import auth as auth_router
from app.routers import content as content_router
from app.routers import dashboard as dashboard_router
from app.routers import quizzes as quizzes_router
from app.routers import subjects as subjects_router
from app.routers import users as users_router

app = FastAPI(title="Rural Edu Platform API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")


@app.get("/health")
def health():
    return {"status": "ok"}


api_router = APIRouter(prefix="/api/v1")
api_router.include_router(auth_router.router, prefix="/auth", tags=["auth"])
api_router.include_router(users_router.router, prefix="/users", tags=["users"])
api_router.include_router(subjects_router.router, prefix="/subjects", tags=["subjects"])
api_router.include_router(content_router.router, prefix="/content", tags=["content"])
api_router.include_router(dashboard_router.router, prefix="/dashboard", tags=["dashboard"])
api_router.include_router(quizzes_router.router, prefix="/quizzes", tags=["quizzes"])

app.include_router(api_router


import os

from fastapi import APIRouter, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.routers import auth as auth_router
from app.routers import content as content_router
from app.routers import dashboard as dashboard_router
from app.routers import quizzes as quizzes_router
from app.routers import subjects as subjects_router
from app.routers import users as users_router

app = FastAPI(title="Rural Edu Platform API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")


@app.get("/health")
def health():
    return {"status": "ok"}


api_router = APIRouter(prefix="/api/v1")
api_router.include_router(auth_router.router, prefix="/auth", tags=["auth"])
api_router.include_router(users_router.router, prefix="/users", tags=["users"])
api_router.include_router(subjects_router.router, prefix="/subjects", tags=["subjects"])
api_router.include_router(content_router.router, prefix="/content", tags=["content"])
api_router.include_router(dashboard_router.router, prefix="/dashboard", tags=["dashboard"])
api_router.include_router(quizzes_router.router, prefix="/quizzes", tags=["quizzes"])

app.include_router(api_router)                   
