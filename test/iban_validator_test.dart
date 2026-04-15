// ignore_for_file: lines_longer_than_80_chars
import 'package:iban_validator/iban_validator.dart';
import 'package:test/test.dart';

void main() {
  group('isValid returns true for valid IBANs', () {
    const validCases = {
      'Germany': 'DE89370400440532013000',
      'UK': 'GB29NWBK60161331926819',
      'France': 'FR7630006000011234567890189',
      'Spain': 'ES7921000813610123456789',
      'Italy': 'IT60X0542811101000000123456',
      'Netherlands': 'NL02ABNA0123456789',
      'Belgium': 'BE71096123456769',
      'Switzerland': 'CH5604835012345678009',
      'Austria': 'AT483200000012345864',
      'Portugal': 'PT50002700000001234567833',
      'Denmark': 'DK9520000123456789',
      'Finland': 'FI1410093000123458',
      'Sweden': 'SE7280000810340009783242',
      'Norway': 'NO8330001234567',
      'Poland': 'PL10105000997603123456789123',
      'Czech Republic': 'CZ5508000000001234567899',
      'Slovakia': 'SK8975000000000012345671',
      'Hungary': 'HU93116000060000000012345676',
      'Romania': 'RO66BACX0000001234567890',
      'Bulgaria': 'BG19STSA93000123456789',
      'Croatia': 'HR1723600001101234565',
      'Slovenia': 'SI56192001234567892',
      'Estonia': 'EE471000001020145685',
      'Lithuania': 'LT601010012345678901',
      'Latvia': 'LV97HABA0012345678910',
      'Luxembourg': 'LU120010001234567891',
      'Malta': 'MT31MALT01100000000000000000123',
      'Cyprus': 'CY21002001950000357001234567',
      'Greece': 'GR9608100010000001234567890',
      'Ireland': 'IE64IRCE92050112345678',
      'Iceland': 'IS750001121234563108962099',
      'Liechtenstein': 'LI7408806123456789012',
      'Monaco': 'MC5810096180790123456789085',
      'Saudi Arabia': 'SA4420000001234567891234',
      'UAE': 'AE460090000000123456789',
      'Turkey': 'TR320010009999901234567890',
      'Israel': 'IL170108000000012612345',
      'Kuwait': 'KW81CBKU0000000000001234560101',
      'Bahrain': 'BH02CITI00001077181611',
      'Qatar': 'QA54QNBA000000000000693123456',
      'Georgia': 'GE60NB0000000123456789',
      'Kazakhstan': 'KZ244350000012344567',
      'Azerbaijan': 'AZ77VTBA00000000001234567890',
      'Brazil': 'BR1500000000000010932840814P2',
      'Costa Rica': 'CR23015108410026012345',
      'Tunisia': 'TN5904018104004942712345',
      'Mauritania': 'MR1300020001010000123456753',
      'Pakistan': 'PK36SCBL0000001123456702',
    };
    for (final entry in validCases.entries) {
      test(entry.key, () => expect(IbanValidator.isValid(entry.value), isTrue));
    }
  });

  group('isValid strips spaces and lowercases', () {
    test(
        'Germany with spaces',
        () => expect(
            IbanValidator.isValid('DE89 3704 0044 0532 0130 00'), isTrue));
    test('UK lowercase',
        () => expect(IbanValidator.isValid('gb29nwbk60161331926819'), isTrue));
  });

  group('isValid returns false for invalid IBANs', () {
    test('empty string', () => expect(IbanValidator.isValid(''), isFalse));
    test('too short', () => expect(IbanValidator.isValid('DE8'), isFalse));
    test('unknown country',
        () => expect(IbanValidator.isValid('XX89370400440532013000'), isFalse));
    test('wrong length',
        () => expect(IbanValidator.isValid('DE893704004405320130'), isFalse));
    test(
        'invalid characters',
        () => expect(
            IbanValidator.isValid('DE89-3704-0044-0532-0130-00'), isFalse));
    test('bad checksum',
        () => expect(IbanValidator.isValid('DE99370400440532013000'), isFalse));
    test(
        'all zeros',
        () =>
            expect(IbanValidator.isValid('DE000000000000000000000'), isFalse));
  });

  group('isValid with countryCca2 constraint', () {
    test(
        'matching country is valid',
        () => expect(
            IbanValidator.isValid('DE89370400440532013000', countryCca2: 'DE'),
            isTrue));
    test(
        'lowercase cca2 is accepted',
        () => expect(
            IbanValidator.isValid('DE89370400440532013000', countryCca2: 'de'),
            isTrue));
    test(
        'mismatched country returns false',
        () => expect(
            IbanValidator.isValid('DE89370400440532013000', countryCca2: 'FR'),
            isFalse));
  });

  group('validate returns correct IbanValidationError', () {
    test('empty → emptyInput', () {
      final r = IbanValidator.validate('');
      expect(r.error, IbanValidationError.emptyInput);
    });
    test('short → tooShort', () {
      final r = IbanValidator.validate('DE8');
      expect(r.error, IbanValidationError.tooShort);
    });
    test('symbols → invalidCharacters', () {
      final r = IbanValidator.validate('DE89-3704-0044-0532-0130-00');
      expect(r.error, IbanValidationError.invalidCharacters);
    });
    test('XX → unknownCountry', () {
      final r = IbanValidator.validate('XX89370400440532013000');
      expect(r.error, IbanValidationError.unknownCountry);
      expect(r.countryInfo, isNull);
    });
    test('wrong cca2 → countryMismatch', () {
      final r =
          IbanValidator.validate('DE89370400440532013000', countryCca2: 'GB');
      expect(r.error, IbanValidationError.countryMismatch);
      expect(r.countryInfo?.countryCode, 'DE');
    });
    test('short for DE → invalidLength', () {
      final r = IbanValidator.validate('DE89370400440532');
      expect(r.error, IbanValidationError.invalidLength);
    });
    test('flipped digit → checksumFailed', () {
      final r = IbanValidator.validate('DE99370400440532013000');
      expect(r.error, IbanValidationError.checksumFailed);
    });
    test('valid → no error, correct country', () {
      final r = IbanValidator.validate('DE89370400440532013000');
      expect(r.isValid, isTrue);
      expect(r.error, isNull);
      expect(r.countryInfo?.countryName, 'Germany');
      expect(r.cleanedIban, 'DE89370400440532013000');
    });
  });

  group('getSupportedCountries', () {
    final codes = IbanValidator.getSupportedCountries();
    test('returns 100+ entries',
        () => expect(codes.length, greaterThanOrEqualTo(100)));
    test('is sorted alphabetically', () => expect(codes, [...codes]..sort()));
    test('contains Eurozone countries', () {
      for (final c in ['DE', 'FR', 'ES', 'IT', 'NL', 'BE', 'AT', 'PT']) {
        expect(codes, contains(c));
      }
    });
    test('contains Middle East countries', () {
      for (final c in ['AE', 'SA', 'BH', 'KW', 'QA', 'IQ', 'JO']) {
        expect(codes, contains(c));
      }
    });
    test('contains African experimental', () {
      for (final c in ['CI', 'SN', 'ML', 'BJ', 'TG', 'BF', 'CM']) {
        expect(codes, contains(c));
      }
    });
    test(
        'list is unmodifiable',
        () =>
            expect(() => (codes as dynamic).add('ZZ'), throwsUnsupportedError));
  });

  group('getCountryInfo', () {
    test('Germany has correct metadata', () {
      final info = IbanValidator.getCountryInfo('DE')!;
      expect(info.countryCode, 'DE');
      expect(info.countryName, 'Germany');
      expect(info.ibanLength, 22);
      expect(info.isSepa, isTrue);
      expect(info.isExperimental, isFalse);
    });
    test('Ivory Coast is experimental', () {
      expect(IbanValidator.getCountryInfo('CI')?.isExperimental, isTrue);
    });
    test('lowercase code works', () {
      expect(IbanValidator.getCountryInfo('gb')?.countryCode, 'GB');
    });
    test('returns null for US', () {
      expect(IbanValidator.getCountryInfo('US'), isNull);
    });
  });

  group('getExpectedLength', () {
    test('Norway shortest (15)',
        () => expect(IbanValidator.getExpectedLength('NO'), 15));
    test('Russia longest (33)',
        () => expect(IbanValidator.getExpectedLength('RU'), 33));
    test('null for unknown',
        () => expect(IbanValidator.getExpectedLength('US'), isNull));
  });

  group('country group helpers', () {
    test('SEPA list covers all EU members', () {
      final codes =
          IbanValidator.getSepaCountries().map((c) => c.countryCode).toList();
      for (final c in [
        'DE',
        'FR',
        'ES',
        'IT',
        'NL',
        'BE',
        'AT',
        'PT',
        'FI',
        'IE',
        'GR',
        'LU',
        'SK',
        'SI',
        'EE',
        'LT',
        'LV',
        'HR',
        'BG',
        'CZ',
        'DK',
        'HU',
        'PL',
        'RO',
        'SE',
        'CY',
        'MT'
      ]) {
        expect(codes, contains(c));
      }
    });
    test(
        'non-SEPA does not contain Germany',
        () => expect(
            IbanValidator.getNonSepaCountries().map((c) => c.countryCode),
            isNot(contains('DE'))));
    test('experimental contains WAEMU zone', () {
      final codes = IbanValidator.getExperimentalCountries()
          .map((c) => c.countryCode)
          .toList();
      for (final c in ['BJ', 'BF', 'CI', 'ML', 'NE', 'SN', 'TG']) {
        expect(codes, contains(c));
      }
    });
    test('no overlap between SEPA and experimental', () {
      final sepa =
          IbanValidator.getSepaCountries().map((c) => c.countryCode).toSet();
      for (final c in IbanValidator.getExperimentalCountries()) {
        expect(sepa, isNot(contains(c.countryCode)));
      }
    });
  });

  group('edge cases', () {
    test(
        'all-spaces input → emptyInput',
        () => expect(IbanValidator.validate('     ').error,
            IbanValidationError.emptyInput));
    test('every registry example passes validation', () {
      final failures = <String>[];
      for (final info in kIbanRegistry.values) {
        if (!IbanValidator.isValid(info.example)) {
          failures.add('${info.countryCode}: ${info.example}');
        }
      }
      expect(failures, isEmpty,
          reason: 'Registry examples failed:\n${failures.join('\n')}');
    });
  });
}
