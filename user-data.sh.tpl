#!/bin/bash
set -e

echo "ENVIRONMENT=${environment}" > /etc/environment.local
chmod 644 /etc/environment.local

# 1. Install System Dependencies
# ruby-full/wget/jq are for AWS Agents; python3-venv is the tool for devs
apt-get update -y
apt-get install -y python3-venv nginx ruby-full wget jq

# 2. Prepare the API Environment
# We use /opt/api as the dedicated home for the backend
mkdir -p /opt/api
chown ubuntu:ubuntu /opt/api

# 3. CodeDeploy Agent (London)
cd /home/ubuntu
wget https://aws-codedeploy-eu-west-2.s3.eu-west-2.amazonaws.com/latest/install
chmod +x ./install
./install auto

# 4. CloudWatch Agent Setup
wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

# Write optimized CloudWatch config (captures all logs in /var/log/)
cat <<EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/*/*.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}-{file_name}"
          }
        ]
      }
    }
  }
}
EOF

# Start agents
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# 5. Finalize Nginx
systemctl enable nginx
systemctl start nginx