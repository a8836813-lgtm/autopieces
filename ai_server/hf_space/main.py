"""AutoPièces AI part scanner: FastAPI service that runs a YOLO model.

Run:   uvicorn main:app --host 0.0.0.0 --port 8000
Test:  curl -F "file=@alternator.jpg" http://localhost:8000/predict

The model file is models/best.pt (made by train_classifier.py). Without it the
server still starts, /health says model_loaded=false and /predict answers 503.

Optional environment variables:
  AI_API_KEY      shared secret; the app sends it in the X-API-Key header
  MODEL_PATH      default models/best.pt
  MIN_CONFIDENCE  predictions below this are dropped (default 0.05)
"""
import io
import os
from pathlib import Path

from fastapi import Depends, FastAPI, File, Header, HTTPException, UploadFile
from PIL import Image, UnidentifiedImageError

MODEL_PATH = Path(os.getenv("MODEL_PATH", "models/best.pt"))
API_KEY = os.getenv("AI_API_KEY", "")
MIN_CONFIDENCE = float(os.getenv("MIN_CONFIDENCE", "0.05"))
MAX_BYTES = 8 * 1024 * 1024  # 8 MB per photo
TOP_K = 3

app = FastAPI(title="AutoPièces AI scanner", version="0.1.0")
_model = None


def get_model():
    """Load the model once, on first use."""
    global _model
    if _model is None:
        if not MODEL_PATH.exists():
            return None
        from ultralytics import YOLO  # imported late so /health is fast

        _model = YOLO(str(MODEL_PATH))
    return _model


def check_key(x_api_key: str = Header(default="")):
    if API_KEY and x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Bad or missing API key")


@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": MODEL_PATH.exists()}


@app.post("/predict", dependencies=[Depends(check_key)])
async def predict(file: UploadFile = File(...)):
    model = get_model()
    if model is None:
        raise HTTPException(status_code=503, detail=f"Model not found at {MODEL_PATH}")

    raw = await file.read()
    if len(raw) > MAX_BYTES:
        raise HTTPException(status_code=413, detail="Photo is larger than 8 MB")
    try:
        image = Image.open(io.BytesIO(raw)).convert("RGB")
    except (UnidentifiedImageError, OSError):
        raise HTTPException(status_code=400, detail="File is not a valid image")

    result = model.predict(image, verbose=False)[0]
    names = result.names
    predictions = []

    if getattr(result, "probs", None) is not None:
        # Classification model: probabilities for every class.
        probs = result.probs
        for idx, conf in zip(probs.top5, probs.top5conf.tolist()):
            predictions.append({"class": names[int(idx)], "confidence": round(conf, 4)})
    else:
        # Detection model: keep the best box per class.
        best = {}
        for box in result.boxes:
            name = names[int(box.cls)]
            conf = float(box.conf)
            if conf > best.get(name, (0, None))[0]:
                best[name] = (conf, [round(v, 1) for v in box.xyxy[0].tolist()])
        for name, (conf, xyxy) in best.items():
            predictions.append({"class": name, "confidence": round(conf, 4), "box": xyxy})

    predictions = [p for p in predictions if p["confidence"] >= MIN_CONFIDENCE]
    predictions.sort(key=lambda p: p["confidence"], reverse=True)
    return {"predictions": predictions[:TOP_K]}
