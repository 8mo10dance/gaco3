#!/bin/bash

set -e

RAILS_PORT=3000
RAILS_PID_FILE="tmp/pids/server.pid"

echo "Starting Rails server..."
bundle exec rails s -p $RAILS_PORT &
RAILS_SERVER_PID=$!

echo "Waiting for Rails server to start..."
for i in $(seq 1 10); do
  if curl -s http://localhost:$RAILS_PORT/up > /dev/null; then
    echo "Rails server started."
    break
  fi
  echo "Attempt $i: Server not ready yet..."
  sleep 2
done

if ! curl -s http://localhost:$RAILS_PORT/up > /dev/null; then
  echo "Error: Rails server did not start within the expected time."
  kill $RAILS_SERVER_PID || true
  exit 1
fi

echo "--- Testing Emojis API ---"

# Create an emoji
echo "Creating an emoji..."
CREATE_EMOJI_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d '{"emoji": {"body": "😀"}}' http://localhost:$RAILS_PORT/api/v1/emojis)
echo "Response: $CREATE_EMOJI_RESPONSE"
EMOJI_ID=$(echo $CREATE_EMOJI_RESPONSE | jq -r '.id')

if [ -z "$EMOJI_ID" ] || [ "$EMOJI_ID" == "null" ]; then
  echo "Error: Failed to create emoji or get ID."
  kill $RAILS_SERVER_PID || true
  exit 1
fi
echo "Created Emoji with ID: $EMOJI_ID"

# List emojis
echo "Listing emojis..."
curl -s http://localhost:$RAILS_PORT/api/v1/emojis

# Get a specific emoji
echo "Getting emoji with ID $EMOJI_ID..."
curl -s http://localhost:$RAILS_PORT/api/v1/emojis/$EMOJI_ID

# Update an emoji
echo "Updating emoji with ID $EMOJI_ID..."
curl -s -X PATCH -H "Content-Type: application/json" -d '{"emoji": {"body": "😃"}}' http://localhost:$RAILS_PORT/api/v1/emojis/$EMOJI_ID

# Delete an emoji
echo "Deleting emoji with ID $EMOJI_ID..."
curl -s -X DELETE http://localhost:$RAILS_PORT/api/v1/emojis/$EMOJI_ID
echo "Emoji deleted."

echo "--- Testing Tags API ---"

# Create a tag
echo "Creating a tag..."
CREATE_TAG_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d '{"tag": {"name": "happy"}}' http://localhost:$RAILS_PORT/api/v1/tags)
echo "Response: $CREATE_TAG_RESPONSE"
TAG_ID=$(echo $CREATE_TAG_RESPONSE | jq -r '.id')

if [ -z "$TAG_ID" ] || [ "$TAG_ID" == "null" ]; then
  echo "Error: Failed to create tag or get ID."
  kill $RAILS_SERVER_PID || true
  exit 1
fi
echo "Created Tag with ID: $TAG_ID"

# List tags
echo "Listing tags..."
curl -s http://localhost:$RAILS_PORT/api/v1/tags

# Get a specific tag
echo "Getting tag with ID $TAG_ID..."
curl -s http://localhost:$RAILS_PORT/api/v1/tags/$TAG_ID

# Update a tag
echo "Updating tag with ID $TAG_ID..."
curl -s -X PATCH -H "Content-Type: application/json" -d '{"tag": {"name": "joy"}}' http://localhost:$RAILS_PORT/api/v1/tags/$TAG_ID

# Delete a tag
echo "Deleting tag with ID $TAG_ID..."
curl -s -X DELETE http://localhost:$RAILS_PORT/api/v1/tags/$TAG_ID
echo "Tag deleted."

echo "Stopping Rails server..."
kill $RAILS_SERVER_PID || true
wait $RAILS_SERVER_PID 2>/dev/null
echo "Rails server stopped."

echo "API verification complete."
