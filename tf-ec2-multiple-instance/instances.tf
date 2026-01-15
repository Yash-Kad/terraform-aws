# instances.tf (Multi-Tier Application Provisioning)

# -----------------------------------------------------------------------------
# 1. Flask Backend Instance
# -----------------------------------------------------------------------------
resource "aws_instance" "flask_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install python3-pip -y
              pip3 install flask flask-cors

              cat << 'PY' > /home/ec2-user/app.py
              from flask import Flask, jsonify
              from flask_cors import CORS

              app = Flask(__name__)
              CORS(app)

              # Professional Data Schema
              names_data = [
                  {"id": 1, "name": "Tony"},
                  {"id": 2, "name": "Steve"},
                  {"id": 3, "name": "yash"},
                  {"id": 4, "name": "alias"}
              ]

              @app.route('/api/names')
              def get_names():
                  return jsonify(names_data)

              if __name__ == '__main__':
                  app.run(host='0.0.0.0', port=5000)
              PY

              python3 /home/ec2-user/app.py &
              EOF

  tags = { Name = "Backend_Flask" }
}

# -----------------------------------------------------------------------------
# 2. Express Frontend Instance
# -----------------------------------------------------------------------------
resource "aws_instance" "express_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              # 1. IMMEDIATE FOLDER CREATION (To prevent missing directory issues)
              WORKDIR="/home/ec2-user/frontend"
              mkdir -p $WORKDIR
              chown ec2-user:ec2-user $WORKDIR

              # 2. Update and Install (Logged for debugging)
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              dnf update -y
              dnf install -y nodejs npm

              # 3. Application Setup
              cd $WORKDIR
              sudo -u ec2-user npm init -y
              sudo -u ec2-user npm install express axios

              # 4. Content Creation
              cat << 'HTML' > index.html
              <!DOCTYPE html>
              <html>
              <head><title>Registry</title></head>
              <body style="background:#0f172a; color:#38bdf8; padding:50px;">
                  <h1>System Personnel Registry</h1>
                  <ul id="list">{{NAMES_LIST}}</ul>
              </body>
              </html>
              HTML

              cat << 'JS' > index.js
              const express = require('express');
              const axios = require('axios');
              const fs = require('fs');
              const app = express();
              const BACKEND_URL = 'http://BACKEND_IP_PLACEHOLDER:5000/api/names';

              app.get('/', async (req, res) => {
                  try {
                      const response = await axios.get(BACKEND_URL, { timeout: 3000 });
                      let html = fs.readFileSync('index.html', 'utf8');
                      let items = response.data.map(n => '<li>' + n.name + '</li>').join('');
                      res.send(html.replace('{{NAMES_LIST}}', items));
                  } catch (e) { res.status(500).send("Error: " + e.message); }
              });
              app.listen(3000, '0.0.0.0');
              JS

              # 5. Injection and Execution
              sed -i 's/BACKEND_IP_PLACEHOLDER/${aws_instance.flask_server.private_ip}/g' index.js
              
              # Ensure ec2-user owns everything before starting
              chown -R ec2-user:ec2-user $WORKDIR
              nohup sudo -u ec2-user node index.js > $WORKDIR/app.log 2>&1 &
              EOF

  tags = { Name = "Frontend_Express" }
}
