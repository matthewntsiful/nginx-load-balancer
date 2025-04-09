#!/bin/bash

# System updates and Nginx setup
apt-get update -y && apt-get upgrade -y
apt-get install nginx -y
systemctl start nginx && systemctl enable nginx

# Get IMDSv2 token (valid for 6 hours)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)

# Retrieve metadata using IMDSv2
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
INSTANCE_TYPE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-type)
AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4)
PUBLIC_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "N/A")
SIGNATURE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/dynamic/instance-identity/signature)

# Create 3D-styled HTML page
HTML_FILE="/var/www/html/index.html"

cat << EOF > $HTML_FILE
<!DOCTYPE html>
<html>
<head>
    <title>LB Test Node - $INSTANCE_ID</title>
    <style>
        body {
            background: linear-gradient(135deg, #1a1a1a 0%, #4a4a4a 100%);
            height: 100vh;
            margin: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            perspective: 1000px;
            font-family: 'Arial Black', Gadget, sans-serif;
        }

        .card {
            background: linear-gradient(45deg, #ffffff, #f8f9fa);
            padding: 3rem;
            border-radius: 20px;
            transform: rotateX(10deg) rotateY(-10deg) rotateZ(2deg);
            box-shadow: 20px 20px 60px rgba(0,0,0,0.5),
                       -5px -5px 15px rgba(255,255,255,0.1);
            border: 2px solid rgba(255,255,255,0.15);
            text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
            transition: transform 0.5s;
            max-width: 800px;
        }

        .card:hover {
            transform: rotateX(0deg) rotateY(0deg) rotateZ(0deg);
        }

        h1 {
            color: #2c3e50;
            font-size: 2.5rem;
            margin-bottom: 2rem;
            text-align: center;
            letter-spacing: 2px;
            text-transform: uppercase;
            border-bottom: 3px solid #2980b9;
            padding-bottom: 1rem;
        }

        .metadata {
            font-size: 1.4rem;
            color: #34495e;
            line-height: 2;
            text-align: left;
        }

        strong {
            color: #2980b9;
            font-weight: 900;
            letter-spacing: 1px;
        }

        .token {
            font-family: monospace;
            font-size: 1rem;
            word-break: break-all;
            background: rgba(0,0,0,0.05);
            padding: 1rem;
            border-radius: 5px;
            margin-top: 1rem;
        }
    </style>
</head>
<body>
    <div class="card">
        <h1>Load Balancer Test Node</h1>
        <div class="metadata">
            <p><strong>Instance ID:</strong> $INSTANCE_ID</p>
            <p><strong>Instance Type:</strong> $INSTANCE_TYPE</p>
            <p><strong>Availability Zone:</strong> $AZ</p>
            <p><strong>Private IP:</strong> $PRIVATE_IP</p>
            <p><strong>Public IP:</strong> $PUBLIC_IP</p>
            <div class="token">
                <strong>Instance Identity Token:</strong><br>
                $SIGNATURE
            </div>
        </div>
    </div>
</body>
</html>
EOF

# Set permissions and restart Nginx
chmod 644 $HTML_FILE
systemctl restart nginx