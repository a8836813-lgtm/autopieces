import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';

import '../data/models.dart';
import 'part_scanner.dart';
import 'scanner_matching.dart';

/// Runs the trained YOLOv8 classifier inside the phone with ONNX Runtime.
/// No server and no internet needed.
///
/// Needs two files in assets/models/ (see assets/models/README.md):
///   part_classifier.onnx  (exported from best.pt)
///   labels.txt            (the 50 class names, one per line, in model order)
class OnDevicePartScanner implements PartScanner {
  static const String modelAsset = 'assets/models/part_classifier.onnx';
  static const String labelsAsset = 'assets/models/labels.txt';
  static const int size = 224;

  OrtSession? _session;
  List<String>? _labels;

  Future<void> _ensureLoaded() async {
    if (_session != null && _labels != null) return;
    final labelsText = await rootBundle.loadString(labelsAsset);
    final labels = labelsText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    // Throws if the model file was not added to the app.
    final data = await rootBundle.load(modelAsset);
    OrtEnv.instance.init();
    final options = OrtSessionOptions();
    _session = OrtSession.fromBuffer(data.buffer.asUint8List(), options);
    _labels = labels;
  }

  @override
  Future<List<MatchCandidate>> identify(List<String> photoPaths) async {
    await _ensureLoaded();
    final labels = _labels!;
    final votes = <String, List<double>>{};
    for (final path in photoPaths) {
      // Decoding a 12 MP photo is slow: do it away from the UI thread.
      final input = await Isolate.run(() => _preprocess(path));
      final probs = await _run(input);
      final order = List<int>.generate(probs.length, (i) => i)
        ..sort((a, b) => probs[b].compareTo(probs[a]));
      for (final i in order.take(3)) {
        if (probs[i] < 0.05 || i >= labels.length) continue;
        votes.putIfAbsent(labels[i], () => []).add(probs[i]);
      }
    }
    return candidatesFromVotes(votes, photoPaths.length);
  }

  Future<List<double>> _run(Float32List input) async {
    final tensor =
        OrtValueTensor.createTensorWithDataList(input, [1, 3, size, size]);
    final runOptions = OrtRunOptions();
    List<OrtValue?>? outputs;
    try {
      outputs = await _session!.runAsync(runOptions, {'images': tensor});
      final raw = outputs?[0]?.value;
      if (raw is! List || raw.isEmpty) {
        throw Exception('The model returned no result');
      }
      final row = raw.first as List;
      final values = row.map((e) => (e as num).toDouble()).toList();
      return _asProbabilities(values);
    } finally {
      tensor.release();
      runOptions.release();
      outputs?.forEach((o) => o?.release());
    }
  }

  /// The exported model already ends with a softmax. If it does not, apply it.
  static List<double> _asProbabilities(List<double> v) {
    final sum = v.fold<double>(0, (a, b) => a + b);
    final inRange = v.every((x) => x >= 0 && x <= 1);
    if (inRange && (sum - 1).abs() < 0.05) return v;
    final maxV = v.reduce(math.max);
    final exps = v.map((x) => math.exp(x - maxV)).toList();
    final total = exps.fold<double>(0, (a, b) => a + b);
    return exps.map((e) => e / total).toList();
  }
}

/// Same steps as the training/validation of YOLO classification:
/// RGB, shortest side resized to 224, centre crop 224x224, values 0..1,
/// channel first (1 x 3 x 224 x 224).
Float32List _preprocess(String path) {
  const size = OnDevicePartScanner.size;
  final bytes = File(path).readAsBytesSync();
  var image = img.decodeImage(bytes);
  if (image == null) throw Exception('Could not read the photo');
  image = img.bakeOrientation(image); // phone photos carry a rotation flag
  final scale = size / math.min(image.width, image.height);
  final w = math.max(size, (image.width * scale).round());
  final h = math.max(size, (image.height * scale).round());
  image = img.copyResize(image,
      width: w, height: h, interpolation: img.Interpolation.linear);
  final x = ((w - size) / 2).round();
  final y = ((h - size) / 2).round();
  image = img.copyCrop(image, x: x, y: y, width: size, height: size);

  final out = Float32List(3 * size * size);
  const plane = size * size;
  for (var yy = 0; yy < size; yy++) {
    for (var xx = 0; xx < size; xx++) {
      final p = image.getPixel(xx, yy);
      final i = yy * size + xx;
      out[i] = p.r / 255.0;
      out[plane + i] = p.g / 255.0;
      out[2 * plane + i] = p.b / 255.0;
    }
  }
  return out;
}
