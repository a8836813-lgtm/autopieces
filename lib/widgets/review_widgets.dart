import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../theme.dart';

/// Read-only stars, for example 4.5 shows four and a half stars.
class StarRow extends StatelessWidget {
  final double stars;
  final double size;

  const StarRow({super.key, required this.stars, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            stars >= i
                ? Icons.star
                : (stars >= i - 0.5 ? Icons.star_half : Icons.star_border),
            size: size,
            color: AppColors.orange,
          ),
      ],
    );
  }
}

/// A single review: stars, author, date and comment.
class ReviewTile extends StatelessWidget {
  final Review review;
  const ReviewTile({super.key, required this.review});

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StarRow(stars: review.stars.toDouble(), size: 15),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.author,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                _date(review.createdAt),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.comment, style: const TextStyle(fontSize: 14)),
          ],
        ],
      ),
    );
  }
}

/// Bottom sheet where the client picks 1 to 5 stars and writes a comment.
/// Returns true when the review was submitted.
Future<bool> showReviewSheet(
  BuildContext context, {
  required String title,
  required void Function(int stars, String comment) onSubmit,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _ReviewSheet(title: title, onSubmit: onSubmit),
  );
  return result == true;
}

class _ReviewSheet extends StatefulWidget {
  final String title;
  final void Function(int stars, String comment) onSubmit;

  const _ReviewSheet({required this.title, required this.onSubmit});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final _comment = TextEditingController();
  int _stars = 0;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _submit() {
    if (_stars == 0) {
      setState(() => _error = 'Tap a star to rate');
      return;
    }
    widget.onSubmit(_stars, _comment.text);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: '$i star${i == 1 ? '' : 's'}',
                  onPressed: () => setState(() {
                    _stars = i;
                    _error = null;
                  }),
                  icon: Icon(
                    i <= _stars ? Icons.star : Icons.star_border,
                    size: 34,
                    color: AppColors.orange,
                  ),
                ),
            ],
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: AppColors.warn)),
          const SizedBox(height: 8),
          TextField(
            controller: _comment,
            maxLines: 3,
            maxLength: 300,
            decoration: const InputDecoration(
              hintText: 'Tell others about your experience (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
              child: const Text('Submit review'),
            ),
          ),
        ],
      ),
    );
  }
}
