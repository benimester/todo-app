import os
from typing import List, Optional
from fastapi import FastAPI, Depends, HTTPException, Security, UploadFile, File, Form
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
import jwt
import httpx
from motor.motor_asyncio import AsyncIOMotorClient
from bson import ObjectId

app = FastAPI(title="Todo Service")

MONGO_URL = os.getenv("MONGO_URL", "mongodb://localhost:27017")
MEDIA_SERVICE_URL = os.getenv("MEDIA_SERVICE_URL", "http://localhost:8002")
JWT_SECRET = os.getenv("JWT_SECRET", "super-secret-key")
ALGORITHM = "HS256"

# MongoDB setup
client = AsyncIOMotorClient(MONGO_URL)
db = client.todo_db
todos_collection = db.get_collection("todos")

security = HTTPBearer()


def get_current_user(credentials: HTTPAuthorizationCredentials = Security(security)):
    token = credentials.credentials
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise HTTPException(status_code=401, detail="Invalid auth token")
        return username
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Invalid auth token")


class TodoResponse(BaseModel):
    id: str
    title: str
    description: str
    photo_url: Optional[str] = None
    username: str


@app.post("/todos", response_model=TodoResponse)
async def create_todo(
    title: str = Form(...),
    description: str = Form(...),
    photo: Optional[UploadFile] = File(None),
    username: str = Depends(get_current_user),
):
    photo_url = None
    if photo:
        # Call Media service
        async with httpx.AsyncClient() as http_client:
            files = {"file": (photo.filename, photo.file, photo.content_type)}
            response = await http_client.post(
                f"{MEDIA_SERVICE_URL.rstrip('/')}/upload", files=files
            )
            if response.status_code == 200:
                photo_url = response.json().get("url")
            else:
                raise HTTPException(
                    status_code=response.status_code, detail="Failed to upload photo"
                )

    todo_doc = {
        "title": title,
        "description": description,
        "photo_url": photo_url,
        "username": username,
    }

    result = await todos_collection.insert_one(todo_doc)

    return TodoResponse(
        id=str(result.inserted_id),
        title=title,
        description=description,
        photo_url=photo_url,
        username=username,
    )


@app.get("/todos", response_model=List[TodoResponse])
async def list_todos(username: str = Depends(get_current_user)):
    cursor = todos_collection.find({"username": username})
    todos = []
    async for document in cursor:
        todos.append(
            TodoResponse(
                id=str(document["_id"]),
                title=document["title"],
                description=document["description"],
                photo_url=document.get("photo_url"),
                username=document["username"],
            )
        )
    return todos


@app.put("/todos/{todo_id}", response_model=TodoResponse)
async def update_todo(
    todo_id: str,
    title: str = Form(...),
    description: str = Form(...),
    photo: Optional[UploadFile] = File(None),
    username: str = Depends(get_current_user),
):
    try:
        obj_id = ObjectId(todo_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid Todo ID")

    existing_todo = await todos_collection.find_one(
        {"_id": obj_id, "username": username}
    )
    if not existing_todo:
        raise HTTPException(status_code=404, detail="Todo not found")

    photo_url = existing_todo.get("photo_url")
    if photo:
        async with httpx.AsyncClient() as http_client:
            files = {"file": (photo.filename, photo.file, photo.content_type)}
            response = await http_client.post(
                f"{MEDIA_SERVICE_URL.rstrip('/')}/upload", files=files
            )
            if response.status_code == 200:
                photo_url = response.json().get("url")
            else:
                raise HTTPException(
                    status_code=response.status_code, detail="Failed to upload photo"
                )

    update_data = {
        "title": title,
        "description": description,
        "photo_url": photo_url,
    }

    await todos_collection.update_one({"_id": obj_id}, {"$set": update_data})

    return TodoResponse(
        id=todo_id,
        title=title,
        description=description,
        photo_url=photo_url,
        username=username,
    )


@app.patch("/todos/{todo_id}", response_model=TodoResponse)
async def patch_todo(
    todo_id: str,
    title: Optional[str] = Form(None),
    description: Optional[str] = Form(None),
    photo: Optional[UploadFile] = File(None),
    username: str = Depends(get_current_user),
):
    try:
        obj_id = ObjectId(todo_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid Todo ID")

    existing_todo = await todos_collection.find_one(
        {"_id": obj_id, "username": username}
    )
    if not existing_todo:
        raise HTTPException(status_code=404, detail="Todo not found")

    update_data = {}
    if title is not None:
        update_data["title"] = title
    if description is not None:
        update_data["description"] = description

    if photo:
        async with httpx.AsyncClient() as http_client:
            files = {"file": (photo.filename, photo.file, photo.content_type)}
            response = await http_client.post(
                f"{MEDIA_SERVICE_URL.rstrip('/')}/upload", files=files
            )
            if response.status_code == 200:
                update_data["photo_url"] = response.json().get("url")
            else:
                raise HTTPException(
                    status_code=response.status_code, detail="Failed to upload photo"
                )

    if update_data:
        await todos_collection.update_one({"_id": obj_id}, {"$set": update_data})

    updated_todo = await todos_collection.find_one({"_id": obj_id})
    return TodoResponse(
        id=todo_id,
        title=updated_todo["title"],
        description=updated_todo["description"],
        photo_url=updated_todo.get("photo_url"),
        username=username,
    )
