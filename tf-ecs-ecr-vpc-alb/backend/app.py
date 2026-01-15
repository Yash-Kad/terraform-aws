from flask import Flask, jsonify
from flask_cors import CORS
import json
import os

app = Flask(__name__)
CORS(app)

# Utility function to load data safely
def load_data():
    file_path = "details.json"
    if not os.path.exists(file_path):
        # Return default data if file is missing to prevent 500 error
        return [{"id": 0, "name": "System", "info": "Data file not found"}]
    
    with open(file_path, "r") as file:
        return json.load(file)
@app.route("/")
def index():
    return "<h1>You Are In Backend Go At /people</h1>"

@app.route("/people", methods=["GET"])
def get_people():
    try:
        data = load_data()
        return jsonify(data)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# MANDATORY: ALB Health Check Route
@app.route("/health", methods=["GET"])
def health():
    return "OK", 200

if __name__ == "__main__":
    # Production containers usually use port 5000 or 8000
    # In ECS, ensure this matches your Task Definition portMapping
    app.run(port=8000, host="0.0.0.0", debug=False)
