import 'package:flutter_test/flutter_test.dart';
import 'package:vipmind/data/models/anki_card_model.dart';

/// The SM-2 spaced-repetition engine already lives in the model — these tests
/// pin its behaviour so the (not yet built) review UI cannot silently change
/// the scheduling a learner depends on.
void main() {
  AnkiCardModel card({int interval = 1, double ease = 2.5, int repetitions = 0}) {
    return AnkiCardModel(
      id: 'card-1',
      front: 'front',
      back: 'back',
      interval: interval,
      easeFactor: ease,
      repetitions: repetitions,
    );
  }

  group('SM-2 scheduling', () {
    test('a brand new card passes to 1 day', () {
      final c = card();
      c.review(5);

      expect(c.repetitions, 1);
      expect(c.interval, 1);
      expect(c.nextReview, isNotNull);
    });

    test('the second successful review jumps to 6 days', () {
      final c = card(repetitions: 1);
      c.review(4);

      expect(c.repetitions, 2);
      expect(c.interval, 6);
    });

    test('later reviews multiply the interval by the ease factor', () {
      final c = card(interval: 6, ease: 2.5, repetitions: 2);
      c.review(4);

      expect(c.interval, 15); // (6 * 2.5).round()
      expect(c.repetitions, 3);
    });

    test('a failed review resets repetitions and interval', () {
      final c = card(interval: 15, ease: 2.5, repetitions: 3);
      c.review(2);

      expect(c.repetitions, 0);
      expect(c.interval, 1);
      expect(c.nextReview, isNotNull);
    });

    test('ease factor grows for a perfect answer and shrinks for a hard one', () {
      final perfect = card();
      perfect.review(5);
      expect(perfect.easeFactor, greaterThan(2.5));

      final hard = card();
      hard.review(3);
      expect(hard.easeFactor, lessThan(2.5));
    });

    test('ease factor never drops below the 1.3 floor', () {
      final c = card(ease: 1.3);
      for (var i = 0; i < 10; i++) {
        c.review(0);
      }
      expect(c.easeFactor, 1.3);
    });

    test('next review date moves forward by the new interval', () {
      final before = DateTime.now();
      final c = card(interval: 6, repetitions: 2);
      c.review(4);

      expect(c.interval, 15);
      expect(
        c.nextReview!.difference(before).inDays,
        inInclusiveRange(14, 15),
      );
      expect(c.isDue, isFalse);
    });

    test('a card with no review date is due immediately', () {
      expect(card().isDue, isTrue);
    });

    test('a card whose review date has passed is due', () {
      final c = card();
      c.nextReview = DateTime.now().subtract(const Duration(hours: 1));
      expect(c.isDue, isTrue);
    });
  });

  group('serialisation', () {
    test('review state survives a JSON round trip', () {
      final c = card(interval: 6, ease: 2.36, repetitions: 2)..review(4);
      final restored = AnkiCardModel.fromJson(c.toJson());

      expect(restored.interval, c.interval);
      expect(restored.repetitions, c.repetitions);
      expect(restored.easeFactor, closeTo(c.easeFactor, 0.0001));
      expect(restored.nextReview, c.nextReview);
    });
  });
}
