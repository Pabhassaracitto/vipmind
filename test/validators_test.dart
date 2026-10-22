import 'package:flutter_test/flutter_test.dart';
import 'package:vipmind/core/utils/validators.dart';

void main() {
  group('email', () {
    test('accepts common addresses', () {
      for (final value in [
        'a@b.co',
        'user.name+tag@example.com',
        'user_name@sub.domain.org',
      ]) {
        expect(Validators.email(value), isNull, reason: value);
      }
    });

    test('rejects malformed addresses and empty input', () {
      for (final value in ['', 'plain', 'a@b', 'a b@c.com', '@no-user.com']) {
        expect(Validators.email(value), isNotNull, reason: value);
      }
      expect(Validators.email(null), isNotNull);
    });
  });

  group('password', () {
    test('needs at least 6 characters', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
      expect(Validators.password(''), isNotNull);
      expect(Validators.password(null), isNotNull);
    });

    test('strong password needs length, case and a digit', () {
      expect(Validators.strongPassword('Abcdefg1'), isNull);
      expect(Validators.strongPassword('abcdefg1'), isNotNull, reason: 'no upper');
      expect(Validators.strongPassword('ABCDEFG1'), isNotNull, reason: 'no lower');
      expect(Validators.strongPassword('Abcdefgh'), isNotNull, reason: 'no digit');
      expect(Validators.strongPassword('Ab1'), isNotNull, reason: 'too short');
    });
  });

  group('name', () {
    test('between 2 and 50 characters', () {
      expect(Validators.name('A'), isNotNull);
      expect(Validators.name('Ab'), isNull);
      expect(Validators.name('a' * 50), isNull);
      expect(Validators.name('a' * 51), isNotNull);
      expect(Validators.name(''), isNotNull);
    });
  });

  group('required / length', () {
    test('required names the field in the message', () {
      expect(Validators.required('', 'Title'), contains('Title'));
      expect(Validators.required(null), contains('This field'));
      expect(Validators.required('x'), isNull);
    });

    test('minLength and maxLength produce reusable validators', () {
      final min = Validators.minLength(4, 'Name');
      expect(min('abc'), isNotNull);
      expect(min('abcd'), isNull);
      expect(min(null), isNotNull);

      final max = Validators.maxLength(4, 'Name');
      expect(max('abcde'), isNotNull);
      expect(max('abcd'), isNull);
      expect(max(null), isNull);
    });
  });

  group('url and phone are optional fields', () {
    test('empty values pass, malformed values fail', () {
      expect(Validators.url(''), isNull);
      expect(Validators.url(null), isNull);
      expect(Validators.url('https://example.com'), isNull);
      expect(Validators.url('example.com'), isNull);
      expect(Validators.url('not a url'), isNotNull);

      expect(Validators.phone(''), isNull);
      expect(Validators.phone('+94 77 1234567'), isNull);
      expect(Validators.phone('123'), isNotNull);
    });
  });
}
