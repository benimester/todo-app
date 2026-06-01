FROM python:3.12-slim

WORKDIR /app

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

COPY pyproject.toml uv.lock ./

RUN uv sync --frozen --no-install-project

COPY *.py .

EXPOSE 8000

ENV AWS_ACCESS_KEY_ID=""
ENV AWS_SECRET_ACCESS_KEY=""
ENV AWS_REGION=""
ENV S3_BUCKET_NAME=""
ENV AWS_ENDPOINT_URL=""

CMD ["uv", "run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
