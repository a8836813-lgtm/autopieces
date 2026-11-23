# On-device AI model

Put the exported model here with exactly this name:

    assets/models/part_classifier.onnx

Make it on your PC (inside ai_server, with the .venv active):

    yolo export model=models\best.pt format=onnx imgsz=224 opset=12

then copy `ai_server\models\best.onnx` to `assets\models\part_classifier.onnx`.

`labels.txt` is the list of the 50 classes in the model's order. If you retrain with other classes, regenerate it
(Kaggle: `print(model.names)`), one name per line, in index order.
