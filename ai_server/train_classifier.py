"""Train the part classifier (run in a Kaggle notebook with GPU on, or locally).

Dataset folder layout (one folder per class, names = the class names used by
the app, see kScannerClassKeywords in lib/services/part_scanner.dart):

  dataset/
    train/  alternator/*.jpg  brake_disc/*.jpg  oil_filter/*.jpg ...
    val/    alternator/*.jpg  ...
    test/   alternator/*.jpg  ...      <- never used for training

Roboflow Universe can export in "Folder structure" (classification) format.
Check each dataset licence before you use it in the report.

Usage:  python train_classifier.py --data dataset --epochs 40
Result: runs/classify/train/weights/best.pt  -> copy to ai_server/models/best.pt
"""
import argparse

from ultralytics import YOLO

ap = argparse.ArgumentParser()
ap.add_argument("--data", default="dataset")
ap.add_argument("--epochs", type=int, default=40)
ap.add_argument("--imgsz", type=int, default=224)
ap.add_argument("--base", default="yolov8n-cls.pt")  # small, fast on CPU
args = ap.parse_args()

model = YOLO(args.base)
model.train(data=args.data, epochs=args.epochs, imgsz=args.imgsz, patience=10)

# Honest numbers for the report: evaluate on the held-out test split.
metrics = model.val(data=args.data, split="test")
print("top1 accuracy:", metrics.top1, " top5 accuracy:", metrics.top5)
