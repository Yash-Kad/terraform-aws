#!/bin/bash
yum update -y

# Install Python & pip
yum install -y python3 pip

# Install Node.js
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Create app directory
mkdir -p /opt/apps
cd /opt/apps

# --------------------
# Flask Backend
# --------------------
mkdir backend
cd backend

cat <<EOF > app.py
from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/people")
def people():
    return jsonify([
        {"name": "Alice"},
        {"name": "Bob"},
        {"name": "Charlie"}
    ])

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF

pip3 install flask

nohup python3 app.py > flask.log 2>&1 &

# --------------------
# Express Frontend
# --------------------
cd /opt/apps
mkdir frontend
cd frontend

cat <<EOF > app.js
const express = require("express");
const axios = require("axios");

const app = express();
const PORT = 3000;
const BACKEND_URL = "http://localhost:5000";

app.get("/", async (req, res) => {
  try {
    const response = await axios.get(\`\${BACKEND_URL}/people\`);
    res.send(response.data);
  } catch (err) {
    res.status(500).send("Backend not reachable");
  }
});

app.listen(PORT, "0.0.0.0", () => {
  console.log("Express running on port 3000");
});
EOF

npm init -y
npm install express axios

nohup node app.js > express.log 2>&1 &

