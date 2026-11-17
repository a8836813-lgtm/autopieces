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
