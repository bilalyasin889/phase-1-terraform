#!/bin/bash
set -e

# 1. Install System Dependencies
# We need python3-venv for the engine, and nginx/ruby-full for the agents
apt-get update -y
apt-get install -y python3-venv nginx ruby-full wget jq

# 2. Prepare the API Environment
# We use /opt/api as the dedicated home for the backend
mkdir -p /opt/api
chown ubuntu:ubuntu /opt/api

# 3. Create the Virtual Environment (Venv)
# This ensures the 'gunicorn' binary is fixed at /opt/api/venv/bin/gunicorn
python3 -m venv /opt/api/venv
/opt/api/venv/bin/pip install --upgrade pip
/opt/api/venv/bin/pip install gunicorn

# 4. CodeDeploy Agent (London)
cd /home/ubuntu
wget https://aws-codedeploy-eu-west-2.s3.eu-west-2.amazonaws.com/latest/install
chmod +x ./install
./install auto

# 5. CloudWatch Agent Setup
wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

# Write your optimized, one-time config
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

# Start the agent using the file above
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json