DateTime weekBeginDate() {
  var now = DateTime.now().toUtc();
  return DateTime.utc(now.year, now.month, now.day - now.weekday, 0, 0, 0);
}

bool isInSameDay(DateTime a, DateTime b) {
  var aDate = a.toUtc();
  var bDate = b.toUtc();
  return (aDate.year == bDate.year &&
      aDate.month == bDate.month &&
      aDate.day == bDate.day);
}
