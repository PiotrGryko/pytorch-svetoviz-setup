#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Enabling and starting Svetoviz service..."
sudo systemctl enable svetoviz
sudo systemctl start svetoviz

echo "Testing Nginx configuration..."
sudo nginx -t

echo "Reloading Nginx..."
sudo systemctl reload nginx

echo "Services started successfully."
sudo systemctl status svetoviz --no-pager