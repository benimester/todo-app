#!/bin/bash
set -e

CF="https://dm4abeo3283b4.cloudfront.net"
IMAGE_PATH="/Users/benimester/Pictures/IMG20250402090855.jpg"

echo "=== 1. Registering user ==="
curl -X POST "$CF/register" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser&password=testpassword"
echo -e "\n"

echo "=== 2. Getting JWT token ==="
TOKEN_RESPONSE=$(curl -s -X POST "$CF/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser&password=testpassword")
echo "Token Response: $TOKEN_RESPONSE"

TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')
if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
  echo "Failed to retrieve access token!"
  exit 1
fi
echo -e "Access Token retrieved successfully.\n"

echo "=== 3. Creating a todo (no upload) ==="
curl -X POST "$CF/todos" \
  -H "Authorization: Bearer $TOKEN" \
  -F "title=Learn FastAPI" \
  -F "description=Read the FastAPI documentation"
echo -e "\n"

echo "=== 4. Creating a todo with photo upload ==="
if [ -f "$IMAGE_PATH" ]; then
  curl -X POST "$CF/todos" \
  -H "Authorization: Bearer $TOKEN" \
  -F "title=Upload Test" \
  -F "description=Testing the photo upload" \
  -F "photo=@$IMAGE_PATH"
else
  echo "Image path not found at $IMAGE_PATH. Skipping upload test."
fi
echo -e "\n"

echo "=== 5. Fetching all todos ==="
curl -X GET "$CF/todos" \
  -H "Authorization: Bearer $TOKEN" | jq .
echo -e "\n"
