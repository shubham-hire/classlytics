#!/bin/bash
export PATH="/opt/homebrew/bin:$PATH"

echo "Seeding database..."
node seed.js > seed.log 2>&1

echo "Starting Node.js server..."
node app.js > server.log 2>&1 &
SERVER_PID=$!

echo "Waiting for server to start..."
sleep 3

# Send Normal Message
echo "--- Testing Normal Message ---"
curl -s -X POST http://localhost:3000/chat/message \
  -H "Content-Type: application/json" \
  -d '{"from": "TCH001", "to": "STU001", "body": "Hello student, please submit your assignment.", "role": "teacher"}' > normal_response.json
cat normal_response.json
echo -e "\n"

# Send AI Trigger
echo "--- Testing AI Trigger without student mention ---"
curl -s -X POST http://localhost:3000/chat/message \
  -H "Content-Type: application/json" \
  -d '{"from": "TCH001", "to": "STU001", "body": "@classAI write a short welcoming prompt for a new class.", "role": "teacher"}' > ai_no_student.json
cat ai_no_student.json
echo -e "\n"

# Send AI Trigger with Student Mention
echo "--- Testing AI Trigger WITH student mention (@STU001) ---"
curl -s -X POST http://localhost:3000/chat/message \
  -H "Content-Type: application/json" \
  -d '{"from": "TCH001", "to": "STU001", "body": "@classAI how is @STU001 performing in attendance?", "role": "teacher"}' > ai_yes_student.json
cat ai_yes_student.json
echo -e "\n"

# Check DB Messages
echo "--- Final Messages in DB ---"
mysql -u root -e "SELECT sender_id, receiver_id, body FROM classlytics_db.messages ORDER BY id DESC LIMIT 5;"

# Stop server
kill $SERVER_PID
echo "(Server killed)"

# Show logs
echo "--- Server Logs Snippet ---"
tail -n 20 server.log
