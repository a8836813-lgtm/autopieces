import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../data/models.dart';
import '../data/repo.dart';
import 'scanner_matching.dart';

/// Turns a set of photos of a part into a ranked list of catalog matches.
///
/// The prototype uses [MockPartScanner]. To make it real, write a class that
/// implements this interface and swap it in where the scan screen creates
/// its scanner. A real version would:
///   1. run an image classifier on each photo (e.g. MobileNet in TFLite),
///   2. run OCR (e.g. Google ML Kit) to read printed part numbers or tire sizes,
///   3. compare image embeddings with the reference photos of catalog parts,
///   4. combine the results of all photos by voting or averaging.
abstract class PartScanner {
  Future<List<MatchCandidate>> identify(List<String> photoPaths);
}

/// Returns a fixed, believable answer so the whole flow can be demonstrated.
class MockPartScanner implements PartScanner {
  @override
  Future<List<MatchCandidate>> identify(List<String> photoPaths) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final repo = Repo.instance;
    final total = photoPaths.length;
    final matched = total >= 3 ? total - 1 : total;
    return [
      MatchCandidate(
        part: repo.partById('p1'),
        confidence: 0.92,
        reason:
            'Matched on $matched of $total photos. The number 5Q0 615 301 was read from one photo.',
      ),
      MatchCandidate(
        part: repo.partById('p2'),
        confidence: 0.05,
        reason: 'Similar shape, but this disc is solid, not ventilated.',
      ),
      MatchCandidate(
        part: repo.partById('p9'),
        confidence: 0.03,
        reason: 'Same family of discs, smaller diameter.',
      ),
    ];
  }
}

/// Sends the photos to the AI server (FastAPI + YOLO) and maps the predicted
/// part type to the parts catalog.
///
/// The AI only recognises what KIND of part it is. It cannot prove that the
/// part fits a given car, so every result asks the user to confirm.
class RemotePartScanner implements PartScanner {
  @override
  Future<List<MatchCandidate>> identify(List<String> photoPaths) async {
    // class name → confidence of each photo that predicted it
    final votes = <String, List<double>>{};
    for (final path in photoPaths) {
      final preds = await _predictOne(path);
      for (final p in preds) {
        votes.putIfAbsent(p.label, () => []).add(p.confidence);
      }
    }
    return candidatesFromVotes(votes, photoPaths.length);
  }

  Future<List<({String label, double confidence})>> _predictOne(String path) async {
    var base = AppConfig.aiScannerUrl;
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    final uri = Uri.parse('$base/predict');
    final req = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', path));
    if (AppConfig.aiScannerApiKey.isNotEmpty) {
      req.headers['X-API-Key'] = AppConfig.aiScannerApiKey;
    }
    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) {
      throw Exception('AI server error ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data['predictions'] as List?) ?? const [];
    return [
      for (final p in list.whereType<Map<String, dynamic>>())
        (
          label: (p['class'] as String?) ?? '',
          confidence: ((p['confidence'] as num?) ?? 0).toDouble(),
        ),
    ].where((p) => p.label.isNotEmpty).toList();
  }
}
