String percentLabel(num? value) {
  if (value == null) return 'N/A';
  return '${(value * 100).round()}%';
}

String scoreLabel(num? value) {
  if (value == null) return 'N/A';
  return '${(value * 100).round()}';
}

String ratingLabel(num? value) {
  if (value == null || value == 0) return '-';
  return value.toStringAsFixed(1);
}

String dateLabel(String? value) {
  if (value == null || value.isEmpty) return '-';
  final date = DateTime.tryParse(value);
  if (date == null) return '-';
  const monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  final localDate = date.toLocal();
  final day = localDate.day.toString().padLeft(2, '0');
  final month = monthNames[localDate.month - 1];
  return '$day $month ${localDate.year}';
}
