const express = require("express");
const path = require("path");
const axios = require("axios");

const app = express();
const PORT = process.env.PORT || 3000;
const BACKEND_URL = process.env.BACKEND_URL || "http://0.0.0.0:8000/people";

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "views", "index.html"));
});

// API route to get data from Flask
app.get("/get-data", async (req, res) => {
  try {
    const response = await axios.get(BACKEND_URL, { timeout: 5000 });
    res.json(response.data);
  } catch (error) {
    // Log exactly what went wrong in the container logs
    console.error(`ERROR: Could not reach ${BACKEND_URL} -> ${error.message}`);
    res.status(500).json({ error: "Backend server not reachable" });
  }
});

app.listen(PORT, () => {
  console.log(`Express running at http://0.0.0.0:${PORT}`);
});
process.on("SIGINT", () => {
  console.log("Shutting down Express server...");
  process.exit(0);
});
