#!/bin/bash

echo "Creating Incident 01: Port 8000 Already In Use"
echo "=============================================="

# Stop the real nginx server
echo "Stopping original server..."
sudo systemctl stop nginx
sleep 1

# Start a fake process on port 8000 to stimulate port conflict with Netcat
echo "Starting a fake process on port 8000..."
nc -1 -p 8000 -q 1 &
FAKE_PID=$!
echo "Fake process started with PID $FAKE_PID"
sleep 2

# Now start nginx server
echo ""
echo "Attempting to start nginx (this will FAIL)..."
sudo systemctl start nginx
sleep 3

# Check server status
echo ""
if sudo systemctl is-active --quiet nginx; then
   echo "Nginx is running (unexpected!)"
else
   echo "Nginx failed to start (expected incident!)"
fi

# Save fake PID
echo $FAKE_PID > /tmp/fake_nginx.pid

echo ""
echo "incident created!"
echo "Port 8000 is now blocked by: $(sudo lsof -i :8000 | grep LISTEN)"

