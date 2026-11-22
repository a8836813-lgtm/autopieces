"""Split a folder of class folders into train / val / test (70 / 15 / 15).

Input  (raw/):  raw/alternator/*.jpg  raw/brake_disc/*.jpg ...
Output (dataset/): dataset/train/<class>/..., dataset/val/..., dataset/test/...

Usage:  python split_dataset.py --src raw --dst dataset
Also prints how many images each class has, so you can spot weak classes.
"""
import argparse
import random
import shutil
from pathlib import Path

ap = argparse.ArgumentParser()
ap.add_argument("--src", default="raw")
ap.add_argument("--dst", default="dataset")
ap.add_argument("--seed", type=int, default=42)
args = ap.parse_args()

random.seed(args.seed)
exts = {".jpg", ".jpeg", ".png", ".webp"}
src, dst = Path(args.src), Path(args.dst)

for cls in sorted(p for p in src.iterdir() if p.is_dir()):
    files = [f for f in cls.iterdir() if f.suffix.lower() in exts]
    random.shuffle(files)
    n = len(files)
    n_train, n_val = int(n * 0.70), int(n * 0.15)
    parts = {
        "train": files[:n_train],
        "val": files[n_train:n_train + n_val],
        "test": files[n_train + n_val:],
    }
    for split, items in parts.items():
        out = dst / split / cls.name
        out.mkdir(parents=True, exist_ok=True)
        for f in items:
            shutil.copy2(f, out / f.name)
    flag = "  <-- too few, add photos" if n < 100 else ""
    print(f"{cls.name:20s} total={n:5d} train={len(parts['train'])} val={len(parts['val'])} test={len(parts['test'])}{flag}")
