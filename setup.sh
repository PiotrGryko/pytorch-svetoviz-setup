#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

APP_DIR="/home/azureuser"
PYTHON_BIN="/home/azureuser/myenv/bin/python3"

echo "Configuring Systemd service..."
sudo bash -c 'cat > /etc/systemd/system/svetoviz.service << EOF
[Unit]
Description=Svetoviz WebGPU Python Server
After=network.target

[Service]
User=azureuser
WorkingDirectory='"$APP_DIR"'
ExecStart='"$PYTHON_BIN"' -c '\''import svetoviz_webgpu as sv; sv.demo_modules(host="127.0.0.1", http_port=8080)'\''
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF'

echo "Writing Nginx configuration file..."
sudo bash -c 'cat > /etc/nginx/sites-available/svetoviz << "EOF"
# Define rate limiting zone: 10MB memory pool, max 10 requests per second per IP
limit_req_zone \$binary_remote_addr zone=svetoviz_limit:10m rate=10r/s;

server {
    listen 80;
    
    # Accept requests matching your domain wildcard and cloudflare domains
    server_name .svetoviz.com .cloudflare.com;

    location / {
        # Apply rate limiting with a burst allowance of 20 requests
        limit_req zone=svetoviz_limit burst=20 nodelay;

        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF'

echo "Enabling Nginx site configuration..."
if [ -L /etc/nginx/sites-enabled/svetoviz ]; then
    sudo rm /etc/nginx/sites-enabled/svetoviz
fi
sudo ln -s /etc/nginx/sites-available/svetoviz /etc/nginx/sites-enabled/

echo "Setup completed successfully."
echo ""
echo "=========================================="
echo "NEXT STEPS TO START THE SERVICES:"
echo "=========================================="
echo ""
echo "1. Start and enable the Python Systemd service:"
echo "   sudo systemctl daemon-reload"
echo "   sudo systemctl enable svetoviz"
echo "   sudo systemctl start svetoviz"
echo ""
echo "2. Check the status of your Python service:"
echo "   sudo systemctl status svetoviz"
echo ""
echo "3. Test your Nginx configuration syntax:"
echo "   sudo nginx -t"
echo ""
echo "4. Reload Nginx to apply the new server configuration:"
echo "   sudo systemctl reload nginx"