
String formatDzd(int value) {
  final s = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
    buffer.write(s[i]);
  }
  return buffer.toString();
}

String stockLabel(int quantity) {
  if (quantity <= 0) return 'Out of stock';
  if (quantity == 1) return 'Low stock · 1 unit';
  return 'In stock · $quantity units';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String formatTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String formatDuration(double hours) {
  final whole = hours == hours.roundToDouble();
  return '${whole ? hours.toInt().toString() : hours.toString()} h';
}
