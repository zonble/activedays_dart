import 'package:active_days/src/date_extensions.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionUnstartedException implements Exception {
  @override
  String toString() => 'You did not start a session.';
}

class InvalidDateException implements Exception {
  @override
  String toString() => 'The incoming date is before the week.';
}

class NeedNewSessionException implements Exception {
  @override
  String toString() =>
      'The incoming date is not in the week. Please start a new session.';
}

abstract class Result {}

class NoChangeResult implements Result {}

class ActiveResult implements Result {
  int days;

  ActiveResult({@required this.days});
}

class ActiveDaysPerWeekCounter {
  final String settingKey;

  DateTime _sessionBeginDate;
  DateTime _lastResultMadeDate;
  int _lastResult;
  bool _dataLoaded;

  String get _sessionBeginDateKey => settingKey + '/sessionBeginDate';

  String get _lastResultMadeDateKey => settingKey + '/lastResultMadeDateKey';

  String get _lastResultKey => settingKey + '/lastResultKey';

  ActiveDaysPerWeekCounter(this.settingKey);

  Future<bool> startNewSessionIfNoExitingOne() async {
    if (_dataLoaded == false) {
      await _load();
    }
    if (_sessionBeginDate == null) {
      return false;
    }
    await this.startSession(DateTime.now());
    return true;
  }

  Future<void> startSession(DateTime date) async {
    _sessionBeginDate = date;
    _lastResult = null;
    _lastResultMadeDate = null;
    await _save();
  }

  Future<Result> commit(DateTime accessDate) async {
    if (_sessionBeginDate == null) {
      throw SessionUnstartedException();
    }
    if (accessDate.isBefore(_sessionBeginDate)) {
      throw InvalidDateException();
    }
    if (accessDate.difference(_sessionBeginDate).inSeconds > 7 * 24 * 60 * 60) {
      throw NeedNewSessionException();
    }
    if (_lastResultMadeDate == null || _lastResult == null) {
      _lastResultMadeDate = DateTime.now();
      _lastResult = 1;
      await _save();
      return ActiveResult(days: 1);
    }
    if (isInSameDay(_lastResultMadeDate, accessDate)) {
      return NoChangeResult();
    }
    final currentDays = _lastResult ?? 0;
    final newDays = currentDays + 1;
    _lastResult = newDays;
    _lastResultMadeDate = accessDate;
    await _save();
    return ActiveResult(days: _lastResult);
  }

  Future<void> _save() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_sessionBeginDate != null) {
      prefs.setInt(
          _sessionBeginDateKey, _sessionBeginDate.millisecondsSinceEpoch);
    } else {
      prefs.remove(_sessionBeginDateKey);
    }

    if (_lastResultMadeDate != null) {
      prefs.setInt(
          _lastResultMadeDateKey, _lastResultMadeDate.millisecondsSinceEpoch);
    } else {
      prefs.remove(_lastResultMadeDateKey);
    }

    if (_lastResult != null) {
      prefs.setInt(_lastResultKey, _lastResult);
    } else {
      prefs.remove(_lastResultKey);
    }
  }

  Future<void> _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final sessionBeginDate = prefs.getInt(_sessionBeginDateKey);
    if (sessionBeginDate != null) {
      _sessionBeginDate = DateTime.fromMillisecondsSinceEpoch(sessionBeginDate);
    }

    final lastResultMadeDate = prefs.getInt(_lastResultMadeDateKey);
    if (lastResultMadeDate != null) {
      _lastResultMadeDate =
          DateTime.fromMillisecondsSinceEpoch(lastResultMadeDate);
    }

    _lastResult = prefs.getInt(_lastResultKey);
    _dataLoaded = true;
  }
}
