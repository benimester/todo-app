import os
import uuid
import boto3
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse

app = FastAPI(title="Media Service")

AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
S3_BUCKET_NAME = os.getenv("S3_BUCKET_NAME")
AWS_ENDPOINT_URL = os.getenv("AWS_ENDPOINT_URL")


def get_s3_client():
    return boto3.client(
        "s3",
        aws_access_key_id=AWS_ACCESS_KEY_ID,
        aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
        region_name=AWS_REGION,
        endpoint_url=AWS_ENDPOINT_URL,
    )


@app.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    if not S3_BUCKET_NAME:
        raise HTTPException(status_code=500, detail="S3 bucket not configured")

    s3_client = get_s3_client()
    file_extension = file.filename.split(".")[-1] if "." in file.filename else ""
    unique_filename = f"{uuid.uuid4()}.{file_extension}"

    try:
        s3_client.upload_fileobj(
            file.file,
            S3_BUCKET_NAME,
            unique_filename,
            ExtraArgs={"ContentType": file.content_type},
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    file_url = (
        f"https://{S3_BUCKET_NAME}.s3.{AWS_REGION}.amazonaws.com/{unique_filename}"
    )
    if AWS_ENDPOINT_URL:
        file_url = f"{AWS_ENDPOINT_URL}/{S3_BUCKET_NAME}/{unique_filename}"

    return {"filename": unique_filename, "url": file_url}


@app.get("/health")
def health_check():
    get_s3_client()
    return {"status": "ok"}
