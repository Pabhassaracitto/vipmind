import 'package:cloud_firestore/cloud_firestore.dart';

// Safe conversion helpers for values coming back from Firestore.
//
// Why this file exists (real bug, found 2026-10-22):
// `MindmapRepository.saveMindmap()` writes
// `data['updatedAt'] = FieldValue.serverTimestamp()`, so Firestore stores a
// **Timestamp**. Every model used to read it back with
// `DateTime.parse(json['updatedAt'])`, which throws
// `type 'Timestamp' is not a subtype of type 'String'` — meaning *any mindmap
// that had been saved could never be loaded again*. The same class of bug hit
// every `double` field: Firestore returns `int` for whole numbers, and
// `Offset(json['positionX'], ...)` then throws `int is not a subtype of double`.
//
// Rule: models must NEVER assume the exact runtime type of a Firestore value.
// Always go through these helpers.

// Reads a date field that may be a [Timestamp], an ISO-8601 [String],
// milliseconds since epoch, or missing.
/// Every branch returns a **UTC** DateTime.
///
/// Dart's `==` on DateTime compares the instant but `hashCode`/`toString` and
/// several matchers are zone-sensitive, and mixing zones is how the millis branch
/// silently compared unequal to a UTC literal. One zone for the whole function
/// removes that class of bug.
DateTime? firestoreDate(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate().toUtc();
  if (value is DateTime) return value.toUtc();
  if (value is String) {
    if (value.isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }
  if (value is int) {
    // UTC, because epoch milliseconds carry no zone. Returning a local DateTime
    // here made `firestoreDate(millis) == utcDate` false for every runner that
    // is not already on UTC — the same instant, a different zone flag.
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
  if (value is double) {
    return DateTime.fromMillisecondsSinceEpoch(value.round(), isUtc: true);
  }
  return null;
}

/// [firestoreDate] with a fallback, for required (`non-nullable`) fields.
DateTime firestoreDateOr(Object? value, DateTime fallback) {
  return firestoreDate(value) ?? fallback;
}

/// Reads a `double` field that Firestore may have stored as an `int`.
double firestoreDouble(Object? value, {double fallback = 0.0}) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

/// Reads an `int` field that may arrive as a `double` (e.g. `3.0`).
int firestoreInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Reads a nested map. `jsonDecode` yields `Map<String, dynamic>`, but values
/// travelling through a Firestore list/array come back as plain `Map`.
Map<String, dynamic> firestoreMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
  return <String, dynamic>{};
}

/// Reads a nested map list (`connections`, etc.).
List<Map<String, dynamic>> firestoreMapList(Object? value) {
  if (value is! List) return <Map<String, dynamic>>[];
  return value.map(firestoreMap).toList();
}

/// Reads a string list without the `List<dynamic> is not a subtype of
/// List<String>` cast error.
List<String> firestoreStringList(Object? value) {
  if (value is! List) return <String>[];
  return value.map((e) => e.toString()).toList();
}

/// Reads an enum stored as its `.index`.
T firestoreEnum<T>(Object? value, List<T> values, {T? fallback}) {
  final index = firestoreInt(value, fallback: -1);
  if (index >= 0 && index < values.length) return values[index];
  if (fallback != null) return fallback;
  return values.first;
}

/// Reads a colour stored as ARGB int by `Color.value`.
int firestoreColorValue(Object? value, {int fallback = 0xFF4A6FA5}) {
  if (value == null) return fallback;
  final number = value is num ? value.toInt() : int.tryParse('$value');
  return number ?? fallback;
}
