FROM python:3.12-slim

WORKDIR /app

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

COPY pyproject.toml uv.lock ./

RUN uv sync --frozen --no-install-project

COPY *.py .

EXPOSE 8000

ENV MONGO_URL=""
ENV MEDIA_SERVICE_URL=""
ENV JWT_SECRET=""

CMD ["uv", "run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
