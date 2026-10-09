FROM python:3.12-slim

WORKDIR /code

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app
COPY alembic.ini .
COPY migrations ./migrations
COPY scripts ./scripts

CMD ["sh", "-c", "alembic upgrade head && python scripts/seed.py && uvicorn app.main:app --host 0.0.0.0 --port 8000"]
