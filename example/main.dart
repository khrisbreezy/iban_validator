// ignore_for_file: avoid_print
import 'package:iban_validator/iban_validator.dart';

void main() {
  // Simple boolean check
  print(IbanValidator.isValid('DE89 3704 0044 0532 0130 00')); // true
  print(IbanValidator.isValid('gb29 nwbk 6016 1331 9268 19')); // true

  // Country constraint
  print(IbanValidator.isValid('DE89370400440532013000',
      countryCca2: 'DE')); // true
  print(IbanValidator.isValid('DE89370400440532013000',
      countryCca2: 'FR')); // false

  // Full result
  final cases = [
    'DE89 3704 0044 0532 0130 00',
    'BADINPUT',
    'DE99370400440532013000',
    '',
  ];
  for (final iban in cases) {
    final r = IbanValidator.validate(iban);
    if (r.isValid) {
      print(
          '✓ ${r.cleanedIban} — ${r.countryInfo!.countryName} (SEPA: ${r.countryInfo!.isSepa})');
    } else {
      print('✗ "${iban.isEmpty ? '<empty>' : iban}" — ${r.errorMessage}');
    }
  }

  // Country metadata
  final de = IbanValidator.getCountryInfo('DE')!;
  print('\nGermany: length=${de.ibanLength}, sepa=${de.isSepa}');
  print('Example: ${de.example}');

  // Enumerate
  print('\nTotal countries: ${IbanValidator.getSupportedCountries().length}');
  print('SEPA: ${IbanValidator.getSepaCountries().length}');
  print('Experimental: ${IbanValidator.getExperimentalCountries().length}');
  print('Shortest IBAN (NO): ${IbanValidator.getExpectedLength('NO')}');
  print('Longest IBAN (RU):  ${IbanValidator.getExpectedLength('RU')}');
}
