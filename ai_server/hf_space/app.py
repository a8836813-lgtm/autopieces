"""Starts the FastAPI scanner (main.py) on the port Hugging Face Spaces expects.

A "Gradio" Space simply runs `python app.py` and shows whatever listens on port 7860,
so we run our own FastAPI app there. The Gradio library itself is not used.
"""
import uvicorn

from main import app

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=7860)
