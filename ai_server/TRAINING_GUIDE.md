# How to build and train the part-recognition model (step by step)

Goal: a file `best.pt` that says what kind of part is in a photo.
Method: image classification with YOLOv8-cls (one photo in, one part type out).

## Step 0. Decide the classes (30 min)
Pick 8 to 12 part types that are in your shop catalog. Example:
alternator, starter_motor, radiator, water_pump, brake_disc, brake_caliper,
shock_absorber, oil_filter, air_filter, clutch_kit, fuel_injector, battery.
Write them in lower case with underscores. These names must match
`kScannerClassKeywords` in `lib/services/part_scanner.dart`.
Do not start with 30. A model with 10 good classes beats 30 bad ones.

## Step 1. Collect images (the longest step)
Target: 150 or more photos per class (100 is the minimum).
Sources, in this order:
1. Kaggle: https://www.kaggle.com/datasets  search "car parts", "auto parts", "brake disc".
2. Roboflow Universe: https://universe.roboflow.com  search the same words,
   filter by "Classification" or "Object detection" and download.
3. Your own photos: go to a local parts shop and photograph parts (10 photos per part,
   different angles, light, backgrounds). Real photos are the most valuable ones
   because they look like what customers will send.
For every dataset write down: name, link, licence. You need this in the report.
Delete wrong, blurry or duplicate images.

## Step 2. Put them in folders
```
raw/
  alternator/   001.jpg 002.jpg ...
  brake_disc/   001.jpg ...
  oil_filter/   ...
```
One folder per class. If a downloaded dataset is in "detection" format (images + label files),
use only the images and sort them into the class folders by hand or by its label names.
Roboflow can also export "Folder Structure" for classification projects.

## Step 3. Split into train / val / test
```
cd ai_server
python split_dataset.py --src raw --dst dataset
```
It creates `dataset/train` (70%), `dataset/val` (15%), `dataset/test` (15%) and prints the
count per class. Classes marked "too few" need more photos.
Rule: the test folder is NEVER used for training. It gives the honest accuracy.

## Step 4. Train on Kaggle (free GPU)
1. Make a Kaggle account and verify your phone number (needed for GPU and internet).
2. Upload your `dataset` folder: Kaggle > Datasets > New Dataset > upload the folder > name it `autopieces-parts`.
3. Kaggle > Code > New Notebook.
4. Right panel > Session options > Accelerator: GPU T4 (or P100). Internet: On.
5. Right panel > Add Input > your `autopieces-parts` dataset. It appears in `/kaggle/input/autopieces-parts/`.
6. Cell 1:
   `!pip install -q ultralytics`
7. Cell 2:
   ```
   from ultralytics import YOLO
   model = YOLO("yolov8n-cls.pt")
   model.train(data="/kaggle/input/autopieces-parts/dataset", epochs=40, imgsz=224, patience=10)
   ```
   (If the dataset is nested one folder deeper, point `data=` to the folder that contains train/ val/ test/.)
8. Wait 10 to 40 minutes. Watch `top1_acc` go up.
9. Cell 3, the honest test:
   `metrics = model.val(data="/kaggle/input/autopieces-parts/dataset", split="test"); print(metrics.top1, metrics.top5)`
10. Download the model: Output tab (right panel) > `runs/classify/train/weights/best.pt` > download.

Training on your own PC also works: `python train_classifier.py --data dataset` (slower without a GPU).

## Step 5. Read the results
- top1 = how often the first answer is right. 0.85 or more on the test set is a good prototype.
- Look at `confusion_matrix.png` in the `runs/classify/train` folder: it shows which parts get mixed up
  (oil filter vs air filter is common). More photos of the confused classes fixes most problems.
- If train accuracy is high but test accuracy is low, the model memorised the training photos (overfitting):
  add more varied photos.

## Step 6. Put the model in the server
Copy `best.pt` to `ai_server/models/best.pt`, then:
```
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
curl -F "file=@test_photo.jpg" http://localhost:8000/predict
```
You should get `{"predictions":[{"class":"alternator","confidence":0.93}]}`.

## Step 7. Connect the app
`flutter run --dart-define=AI_SCANNER_URL=http://10.0.2.2:8000` (emulator) or your PC IP for a real phone.
Open Scan, take 2 or 3 photos, press identify.

## Step 8. Improve (optional, shows depth in the report)
- Photos taken by real users in the app (with consent) go back into `raw/`, retrain.
- Try `yolov8s-cls.pt` (bigger) and compare accuracy and speed in a table.
- Report: dataset sizes, classes, accuracy per class, confusion matrix, response time on a phone.
