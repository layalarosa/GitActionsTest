#!/bin/sh
set -e

echo "Waiting for API healthcheck..."
for i in $(seq 1 30); do
  if curl --fail --silent http://localhost:80/api/health > /dev/null 2>&1; then
    echo "API is healthy"
    break
  fi
  sleep 2
done

echo "Testing index.html..."
if curl --fail --silent http://localhost:80/ | grep -q "Arquitectura Docker"; then
  echo "PASS: index.html contains expected content"
else
  echo "FAIL: index.html content not found"
  exit 1
fi

echo "Testing API health endpoint..."
HEALTH=$(curl --fail --silent http://localhost:80/api/health)
echo "$HEALTH" | grep -q '"status":"healthy"' && echo "PASS: API healthcheck" || { echo "FAIL: API healthcheck"; exit 1; }

echo "Testing POST /api/items..."
RESP=$(curl --fail --silent -X POST http://localhost:80/api/items \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Item","description":"Integration test"}')
echo "$RESP" | grep -q '"name":"Test Item"' && echo "PASS: POST /api/items" || { echo "FAIL: POST /api/items"; exit 1; }

echo "Testing GET /api/items..."
ITEMS=$(curl --fail --silent http://localhost:80/api/items)
echo "$ITEMS" | grep -q "Test Item" && echo "PASS: GET /api/items contains new item" || { echo "FAIL: GET /api/items"; exit 1; }

echo "All integration tests passed!"
