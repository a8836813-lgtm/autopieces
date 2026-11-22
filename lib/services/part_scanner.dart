import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../data/models.dart';
import '../data/repo.dart';

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

/// Picks the real scanner when the AI server address is set in AppConfig,
/// otherwise the demo scanner, so the app always works.
class PartScannerFactory {
  PartScannerFactory._();

  static PartScanner create() =>
      AppConfig.aiScannerConfigured ? RemotePartScanner() : MockPartScanner();
}

/// Words that identify each AI class in the names of catalog parts.
/// The keys are the class names the model is trained with (ai_server/README.md).
/// Add a line here when you add a class or a new kind of part to the catalog.
const Map<String, List<String>> kScannerClassKeywords = {
  'brake_disc': ['brake disc'],
  'brake_pad': ['brake pad'],
  'brake_caliper': ['caliper'],
  'oil_filter': ['oil filter'],
  'air_filter': ['air filter'],
  'alternator': ['alternator'],
  'starter_motor': ['starter'],
  'radiator': ['radiator'],
  'water_pump': ['water pump'],
  'turbocharger': ['turbo'],
  'shock_absorber': ['shock absorber', 'shock'],
  'clutch_kit': ['clutch'],
  'fuel_injector': ['injector'],
  'battery': ['battery'],
  'tire': ['tire', 'tyre'],
  'rim': ['rim'],
};

/// Sends the photos to the AI server (FastAPI + YOLO) and maps the predicted
/// part type to the parts catalog.
///
/// The AI only recognises what KIND of part it is. It cannot prove that the
/// part fits a given car, so every result asks the user to confirm.
class RemotePartScanner implements PartScanner {
  /// Below this confidence the result is shown as "not sure".
  static const double sureThreshold = 0.60;

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
    if (votes.isEmpty) return const [];

    // Average over ALL photos: a class seen in only one of three photos is
    // weaker than a class seen in all three.
    final total = photoPaths.length;
    final scored = votes.entries.map((e) {
      final sum = e.value.fold<double>(0, (a, b) => a + b);
      return (label: e.key, score: sum / total, seen: e.value.length);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final repo = Repo.instance;
    final out = <MatchCandidate>[];
    final used = <String>{};
    for (final c in scored.take(3)) {
      final words = kScannerClassKeywords[c.label] ?? [c.label.replaceAll('_', ' ')];
      final nice = c.label.replaceAll('_', ' ');
      for (final part in repo.parts) {
        final name = part.name.toLowerCase();
        if (!words.any((w) => name.contains(w)) || !used.add(part.id)) continue;
        final percent = (c.score * 100).round();
        out.add(MatchCandidate(
          part: part,
          confidence: c.score,
          reason: c.score >= sureThreshold
              ? 'The AI sees a $nice ($percent%, ${c.seen} of $total photos). Check the serial number and your car before you buy.'
              : 'The AI is not sure ($percent%), it may be a $nice. Add a closer photo or check the serial number.',
        ));
      }
    }
    return out;
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
