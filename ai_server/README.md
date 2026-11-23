# AutoPièces AI part scanner (FastAPI + YOLO)

The phone sends a photo, this server answers what kind of part it is.
It recognises the **type** of part only. It does not prove that the part fits a car.

## 1. Run it (PC with Python 3.10+)
```
cd ai_server
python -m venv .venv && .venv\Scripts\activate     # Linux/Mac: source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```
Open http://localhost:8000/health. `model_loaded: false` is normal until step 2 is done.

## 2. Get a model
1. Collect images, 10 to 30 classes, 100+ photos per class if possible (Kaggle, Roboflow Universe, your own photos). Check the licences.
2. Put them in `dataset/train`, `dataset/val`, `dataset/test` (see `train_classifier.py`).
3. `python train_classifier.py --data dataset` (Kaggle: turn on GPU, 10 to 30 min).
4. Copy `runs/classify/train/weights/best.pt` to `ai_server/models/best.pt`.
5. Test: `curl -F "file=@photo.jpg" http://localhost:8000/predict`

Answer format:
```
{"predictions": [{"class": "alternator", "confidence": 0.94}]}
```

## 3. Connect the Flutter app
In `lib/config/app_config.dart` (or with --dart-define):
```
flutter run --dart-define=AI_SCANNER_URL=http://10.0.2.2:8000          # emulator
flutter run --dart-define=AI_SCANNER_URL=http://192.168.1.20:8000      # real phone, same Wi-Fi
```
Without `AI_SCANNER_URL` the app keeps using the demo scanner (MockPartScanner).
The server must listen on 0.0.0.0 and the PC firewall must allow port 8000.
Android blocks plain http outside the emulator on new versions: use https when hosted
(or add `android:usesCleartextTraffic="true"` for local tests only).

Class names → catalog parts: `kScannerClassKeywords` in `lib/services/part_scanner.dart`.

## 4. Security and hosting
- Set `AI_API_KEY=somesecret` on the server and `--dart-define=AI_SCANNER_API_KEY=somesecret` in the app. A key inside an app can be extracted, so treat it as a speed bump, not real security. Real protection comes with Supabase login later.
- Free CPU hosts for a demo: Hugging Face Spaces (Docker), Render. A small YOLO classifier runs fine on CPU.
- Photos are not stored by this server.

## 5. Put the server online (Hugging Face Spaces, free)
Files to upload to the Space: `Dockerfile`, `main.py`, `requirements.txt`, `models/best.pt`.
1. huggingface.co > New Space > SDK **Docker** (Blank) > hardware **CPU basic (free)**.
2. Files tab > Add file > Upload files (drag the 4 items above, keep the `models` folder).
3. Wait for the build (5 to 15 minutes). The Space then shows **Running**.
4. Test `https://<user>-<space>.hf.space/health` in a browser.
5. App: `flutter run --dart-define=AI_SCANNER_URL=https://<user>-<space>.hf.space`.
6. Optional: Space > Settings > Variables and secrets > secret `AI_API_KEY`, and the same value in the app with `--dart-define=AI_SCANNER_API_KEY=...`.
A free Space goes to sleep after some days without visitors and wakes up on the next request (the first scan can take 1 to 2 minutes). Open `/health` before a demo.

(For the free Gradio-Space route use the files in hf_space/, see hf_space/FILES_TO_UPLOAD.txt.)
