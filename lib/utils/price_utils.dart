double calculateTotalPrice({
  required double basePrice,
  required List<String> facilities,
  required DateTime startDate,
  required DateTime endDate,
}) {
  final days = endDate.difference(startDate).inDays + 1;
  return basePrice + (facilities.length * 50) + (days * 130);
}
