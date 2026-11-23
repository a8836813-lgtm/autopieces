import '../data/models.dart';
import '../data/repo.dart';

/// Below this confidence the result is shown as "not sure".
const double kSureThreshold = 0.60;

/// The 50 classes of the trained model (Kaggle "car parts 50" dataset),
/// lower case, mapped to a catalog category for parts we do not stock yet.
const Map<String, String> kScannerClassCategory = {
  'air compressor': 'Air conditioning',
  'alternator': 'Electrical',
  'battery': 'Battery',
  'brake caliper': 'Brakes',
  'brake pad': 'Brakes',
  'brake rotor': 'Brakes',
  'camshaft': 'Engine',
  'carberator': 'Engine',
  'clutch plate': 'Gearbox',
  'coil spring': 'Suspension',
  'crankshaft': 'Engine',
  'cylinder head': 'Engine',
  'distributor': 'Engine',
  'engine block': 'Engine',
  'engine valve': 'Engine',
  'fuel injector': 'Engine',
  'fuse box': 'Electrical',
  'gas cap': 'Body',
  'headlights': 'Electrical',
  'idler arm': 'Suspension',
  'ignition coil': 'Engine',
  'instrument cluster': 'Electrical',
  'leaf spring': 'Suspension',
  'lower control arm': 'Suspension',
  'muffler': 'Exhaust',
  'oil filter': 'Filters',
  'oil pan': 'Engine',
  'oil pressure sensor': 'Engine',
  'overflow tank': 'Cooling',
  'oxygen sensor': 'Exhaust',
  'piston': 'Engine',
  'pressure plate': 'Gearbox',
  'radiator': 'Cooling',
  'radiator fan': 'Cooling',
  'radiator hose': 'Cooling',
  'radio': 'Electrical',
  'rim': 'Rims',
  'shift knob': 'Body',
  'side mirror': 'Body',
  'spark plug': 'Engine',
  'spoiler': 'Body',
  'starter': 'Electrical',
  'taillights': 'Electrical',
  'thermostat': 'Cooling',
  'torque converter': 'Gearbox',
  'transmission': 'Gearbox',
  'vacuum brake booster': 'Brakes',
  'valve lifter': 'Engine',
  'water pump': 'Cooling',
  'window regulator': 'Body',
};

/// Words used to find the matching part in OUR catalog (repo.parts).
/// A class that is not listed here has no stocked part yet: the app then
/// shows the AI's guess as a new part so the user still gets an answer.
/// Add a line when you add a part to the catalog.
const Map<String, List<String>> kScannerClassKeywords = {
  'brake rotor': ['brake disc'],
  'brake pad': ['brake pad'],
  'oil filter': ['oil filter'],
  'battery': ['battery'],
  'rim': ['rim'],
};

String _normalizeLabel(String raw) =>
    raw.toLowerCase().replaceAll('_', ' ').trim();

String _titleCase(String s) => s
    .split(' ')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');

/// Turns the class votes of the photos into catalog matches.
/// [votes]: class name → confidence of each photo that predicted it.
/// Used by both the server scanner and the on-device scanner.
List<MatchCandidate> candidatesFromVotes(
    Map<String, List<double>> votes, int total) {
  if (votes.isEmpty) return const [];

  // Average over ALL photos: a class seen in only one of three photos is
  // weaker than a class seen in all three.
  final scored = votes.entries.map((e) {
    final sum = e.value.fold<double>(0, (a, b) => a + b);
    return (label: e.key, score: sum / total, seen: e.value.length);
  }).toList()
    ..sort((a, b) => b.score.compareTo(a.score));

  final repo = Repo.instance;
  final out = <MatchCandidate>[];
  final used = <String>{};
  for (final c in scored.take(3)) {
    final label = _normalizeLabel(c.label);
    final nice = label;
    final percent = (c.score * 100).round();
    final reason = c.score >= kSureThreshold
        ? 'The AI sees a $nice ($percent%, ${c.seen} of $total photos). Check the serial number and your car before you buy.'
        : 'The AI is not sure ($percent%), it may be a $nice. Add a closer photo or check the serial number.';
    final words = kScannerClassKeywords[label];
    var found = false;
    if (words != null) {
      for (final part in repo.parts) {
        final name = part.name.toLowerCase();
        if (!words.any((w) => name.contains(w)) || !used.add(part.id)) {
          continue;
        }
        found = true;
        out.add(MatchCandidate(
            part: part, confidence: c.score, reason: reason));
      }
    }
    if (!found) {
      // Not in the catalog yet: register the AI's guess as a part so every
      // screen (results, shop stock editor) can work with its id.
      final id = 'ai_${label.replaceAll(' ', '_')}';
      if (!used.add(id)) continue;
      Part? part;
      for (final p in repo.parts) {
        if (p.id == id) part = p;
      }
      part ??= () {
        final created = Part(
          id: id,
          name: _titleCase(label),
          oem: 'not set',
          category: kScannerClassCategory[label] ?? 'Other',
          fits: 'Found by the AI, confirm with the serial number',
        );
        repo.parts.add(created);
        return created;
      }();
      out.add(MatchCandidate(
          part: part, confidence: c.score, reason: reason));
    }
  }
  return out;
}
