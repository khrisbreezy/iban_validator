# iban_validator

[![pub package](https://img.shields.io/pub/v/iban_validator.svg)](https://pub.dev/packages/iban_validator)
[![pub points](https://img.shields.io/pub/points/iban_validator)](https://pub.dev/packages/iban_validator/score)
[![Dart CI](https://github.com/khrisbreezy/iban_validator/actions/workflows/dart.yml/badge.svg)](https://github.com/khrisbreezy/iban_validator/actions)
[![codecov](https://codecov.io/gh/khrisbreezy/iban_validator/branch/main/graph/badge.svg)](https://codecov.io/gh/khrisbreezy/iban_validator)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![style: recommended](https://img.shields.io/badge/style-recommended-4BC51D.svg)](https://pub.dev/packages/lints)

A comprehensive, **zero-dependency** IBAN validator for **Dart** and **Flutter**.

Built on the ISO 7064 MOD-97-10 algorithm and the official SWIFT IBAN registry, it covers every country in the world that uses IBAN for banking transactions — from Germany and the UK to Saudi Arabia, Ivory Coast, and Brazil.

```dart
IbanValidator.isValid('DE89 3704 0044 0532 0130 00'); // true  ✓
IbanValidator.isValid('GB29 NWBK 6016 1331 9268 19'); // true  ✓
IbanValidator.isValid('DE99 3704 0044 0532 0130 00'); // false ✗ bad checksum
```

---

## Features

- ✅ **116 country codes** — 94 official ISO 13616 countries + 22 experimental (full list below)
- ✅ **Typed error enum** — know exactly why an IBAN failed, not just that it did
- ✅ **Rich country metadata** — name, IBAN length, SEPA membership, and a sample IBAN per country
- ✅ **Input-tolerant** — strips spaces and handles lowercase automatically
- ✅ **Pure Dart** — no Flutter dependency, runs on mobile, web, desktop, and server
- ✅ **Zero dependencies** — nothing in `dependencies:`, only `test` and `lints` in dev
- ✅ **Every registry example tested** — the test suite validates the sample IBAN for all 116 countries

---

## Table of contents

- [Installation](#installation)
- [Quick start](#quick-start)
- [Flutter usage](#flutter-usage)
- [API reference](#api-reference)
  - [isValid](#ibanvalidatorisvalid)
  - [validate](#ibanvalidatorvalidate)
  - [IbanValidationResult](#ibanvalidationresult)
  - [IbanValidationError](#ibanvalidationerror)
  - [getSupportedCountries](#ibanvalidatorgetsupportedcountries)
  - [getCountryInfo](#ibanvalidatorgetcountryinfo)
  - [IbanCountryInfo](#ibancountryinfo)
  - [Other helpers](#other-helpers)
- [Error handling patterns](#error-handling-patterns)
- [How IBAN validation works](#how-iban-validation-works)
- [Supported countries](#supported-countries)
- [Contributing](#contributing)
- [License](#license)

---

## Installation

Add `iban_validator` to your `pubspec.yaml`:

```yaml
dependencies:
  iban_validator: ^1.0.2
```

Then install:

```sh
# Dart
dart pub get

# Flutter
flutter pub get
```

---

## Quick start

```dart
import 'package:iban_validator/iban_validator.dart';

void main() {
  // ── Simple boolean check ───────────────────────────────────────────────────
  print(IbanValidator.isValid('DE89 3704 0044 0532 0130 00')); // true
  print(IbanValidator.isValid('GB29 nwbk 6016 1331 9268 19')); // true  (lowercase OK)
  print(IbanValidator.isValid('BADINPUT'));                     // false

  // ── Country-constrained check ──────────────────────────────────────────────
  // Useful when your form already knows which country the user is in.
  print(IbanValidator.isValid('DE89370400440532013000', countryCca2: 'DE')); // true
  print(IbanValidator.isValid('DE89370400440532013000', countryCca2: 'FR')); // false

  // ── Full validation result ─────────────────────────────────────────────────
  final result = IbanValidator.validate('DE99370400440532013000');
  if (!result.isValid) {
    print(result.error);        // IbanValidationError.checksumFailed
    print(result.errorMessage); // "The mod-97 checksum failed. The IBAN contains an error."
    print(result.countryInfo?.countryName); // Germany
  }

  // ── Country metadata ───────────────────────────────────────────────────────
  final info = IbanValidator.getCountryInfo('GB')!;
  print(info.countryName); // United Kingdom
  print(info.ibanLength);  // 22
  print(info.isSepa);      // true
  print(info.example);     // GB29NWBK60161331926819

  // ── Enumerate countries ────────────────────────────────────────────────────
  final all   = IbanValidator.getSupportedCountries();     // ['AD', 'AE', ...]
  final sepa  = IbanValidator.getSepaCountries();          // SEPA zone only
  final extra = IbanValidator.getExperimentalCountries();  // Africa + Iran
}
```

---

## Flutter usage

### Form validation with `TextFormField`

The most common use case — validating an IBAN field inside a Flutter form:

```dart
import 'package:flutter/material.dart';
import 'package:iban_validator/iban_validator.dart';

class IbanFormField extends StatelessWidget {
  const IbanFormField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'IBAN',
        hintText: 'DE89 3704 0044 0532 0130 00',
      ),
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.characters,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter an IBAN.';
        }
        final result = IbanValidator.validate(value);
        if (!result.isValid) {
          return result.errorMessage;
        }
        return null; // valid
      },
    );
  }
}
```

### Country-locked field

When your app already knows the user's country (e.g. from their profile or a country picker):

```dart
TextFormField(
  decoration: const InputDecoration(labelText: 'Bank account (IBAN)'),
  validator: (value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final result = IbanValidator.validate(
      value,
      countryCca2: selectedCountryCode, // e.g. 'FR', 'NG', 'AE'
    );
    return result.isValid ? null : result.errorMessage;
  },
);
```

### Showing real-time feedback as the user types

```dart
class _IbanFieldState extends State<IbanField> {
  IbanValidationResult? _result;

  void _onChanged(String value) {
    setState(() {
      _result = value.replaceAll(' ', '').length >= 15
          ? IbanValidator.validate(value)
          : null; // don't show errors while typing short strings
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(onChanged: _onChanged),
        if (_result != null) ...[
          const SizedBox(height: 4),
          if (_result!.isValid)
            Text(
              '✓ Valid · ${_result!.countryInfo!.countryName}',
              style: const TextStyle(color: Colors.green),
            )
          else
            Text(
              '✗ ${_result!.errorMessage}',
              style: const TextStyle(color: Colors.red),
            ),
        ],
      ],
    );
  }
}
```

### Displaying country info after successful validation

```dart
void _onSubmit(String iban) {
  final result = IbanValidator.validate(iban);
  if (result.isValid) {
    final info = result.countryInfo!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('IBAN confirmed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Country: ${info.countryName}'),
            Text('SEPA zone: ${info.isSepa ? "Yes" : "No"}'),
            Text('Length: ${info.ibanLength} characters'),
          ],
        ),
      ),
    );
  }
}
```

### Building a country picker backed by the registry

```dart
DropdownButtonFormField<String>(
  hint: const Text('Select country'),
  items: IbanValidator.getSupportedCountries().map((code) {
    final info = IbanValidator.getCountryInfo(code)!;
    return DropdownMenuItem(
      value: code,
      child: Text('${info.countryName} ($code)'),
    );
  }).toList(),
  onChanged: (value) => setState(() => _selectedCountry = value),
);
```

---

## API reference

### `IbanValidator.isValid`

```dart
static bool isValid(String iban, {String? countryCca2})
```

Returns `true` if `iban` passes all validation checks.

- Spaces are stripped and the string is uppercased automatically.
- If `countryCca2` is provided, the IBAN's country code must match it (case-insensitive). Pass the two-letter ISO 3166-1 alpha-2 code, e.g. `'DE'`, `'GB'`, `'AE'`.
- For detailed failure information use [`validate`](#ibanvalidatorvalidate) instead.

```dart
IbanValidator.isValid('DE89 3704 0044 0532 0130 00');         // true
IbanValidator.isValid('de89370400440532013000');              // true  (lowercase)
IbanValidator.isValid('DE89370400440532013000', countryCca2: 'DE'); // true
IbanValidator.isValid('DE89370400440532013000', countryCca2: 'fr'); // false
IbanValidator.isValid('');                                    // false
```

---

### `IbanValidator.validate`

```dart
static IbanValidationResult validate(String iban, {String? countryCca2})
```

Returns an [`IbanValidationResult`](#ibanvalidationresult) with full detail about what passed or failed.

Validation runs in this exact order, stopping at the first failure:

| Step | Check                                              |
| ---- | -------------------------------------------------- |
| 1    | Strip spaces, uppercase                            |
| 2    | Not empty                                          |
| 3    | At least 4 characters                              |
| 4    | Only A–Z and 0–9 characters                        |
| 5    | Country code exists in the registry                |
| 6    | Country code matches `countryCca2` (if provided)   |
| 7    | Length matches the expected length for the country |
| 8    | mod-97 checksum equals 1                           |

---

### `IbanValidationResult`

The object returned by `validate()`.

| Property       | Type                   | Description                                                                            |
| -------------- | ---------------------- | -------------------------------------------------------------------------------------- |
| `isValid`      | `bool`                 | `true` if all checks passed                                                            |
| `cleanedIban`  | `String`               | The uppercased, space-stripped IBAN that was evaluated                                 |
| `error`        | `IbanValidationError?` | Typed failure reason, or `null` when valid                                             |
| `errorMessage` | `String?`              | Human-readable description of the failure                                              |
| `countryInfo`  | `IbanCountryInfo?`     | Country metadata — populated whenever the country code was recognised, even on failure |

```dart
final r = IbanValidator.validate('GB29 NWBK 6016 1331 9268 19');

r.isValid;               // true
r.cleanedIban;           // 'GB29NWBK60161331926819'
r.error;                 // null
r.errorMessage;          // null
r.countryInfo?.countryName; // 'United Kingdom'
r.countryInfo?.isSepa;      // true
```

---

### `IbanValidationError`

Enum returned in `IbanValidationResult.error` when validation fails.

| Value               | Trigger                                                     |
| ------------------- | ----------------------------------------------------------- |
| `emptyInput`        | Input is empty (or whitespace only)                         |
| `tooShort`          | Fewer than 4 characters after stripping spaces              |
| `invalidCharacters` | Contains characters other than A–Z and 0–9                  |
| `unknownCountry`    | First two characters are not a recognised IBAN country code |
| `countryMismatch`   | Country code doesn't match the `countryCca2` constraint     |
| `invalidLength`     | Length doesn't match the expected length for the country    |
| `checksumFailed`    | mod-97 checksum is not 1 — the IBAN number itself is wrong  |

```dart
switch (result.error) {
  case IbanValidationError.unknownCountry:
    // show country picker
  case IbanValidationError.invalidLength:
    // show expected length hint
  case IbanValidationError.checksumFailed:
    // ask user to double-check the number
  default:
    // generic error message
}
```

---

### `IbanValidator.getSupportedCountries`

```dart
static List<String> getSupportedCountries()
```

Returns a sorted, unmodifiable `List<String>` of all supported two-letter country codes. Includes both official ISO 13616 countries and experimental countries.

```dart
final codes = IbanValidator.getSupportedCountries();
// ['AD', 'AE', 'AL', 'AM', 'AO', ..., 'YE']
print(codes.length); // 116
```

---

### `IbanValidator.getCountryInfo`

```dart
static IbanCountryInfo? getCountryInfo(String countryCode)
```

Returns [`IbanCountryInfo`](#ibancountryinfo) for the given code, or `null` if the country is not supported. The lookup is case-insensitive.

```dart
IbanValidator.getCountryInfo('DE');  // IbanCountryInfo(DE, length: 22, sepa: true)
IbanValidator.getCountryInfo('de');  // same result
IbanValidator.getCountryInfo('US');  // null — USA does not use IBAN
```

---

### `IbanCountryInfo`

Registry metadata for a single IBAN-supporting country.

| Field            | Type     | Description                                                               |
| ---------------- | -------- | ------------------------------------------------------------------------- |
| `countryCode`    | `String` | Two-letter ISO 3166-1 alpha-2 code, e.g. `'DE'`                           |
| `countryName`    | `String` | Human-readable country name, e.g. `'Germany'`                             |
| `ibanLength`     | `int`    | Fixed IBAN length for this country, e.g. `22`                             |
| `isSepa`         | `bool`   | Whether the country is in the SEPA payment area                           |
| `isExperimental` | `bool`   | `true` for countries not yet in the official ISO 13616 registry           |
| `example`        | `String` | A known-valid sample IBAN — useful for documentation and placeholder text |

```dart
final info = IbanValidator.getCountryInfo('SA')!;
info.countryCode;     // 'SA'
info.countryName;     // 'Saudi Arabia'
info.ibanLength;      // 24
info.isSepa;          // false
info.isExperimental;  // false
info.example;         // 'SA4420000001234567891234'
```

---

### Other helpers

```dart
// All countries in the SEPA payment area, sorted by code
List<IbanCountryInfo> IbanValidator.getSepaCountries()

// All supported countries outside SEPA, sorted by code
List<IbanCountryInfo> IbanValidator.getNonSepaCountries()

// Countries with experimental/partial IBAN support, sorted by code
List<IbanCountryInfo> IbanValidator.getExperimentalCountries()

// Expected IBAN length for a country code, or null if unsupported
int? IbanValidator.getExpectedLength(String countryCode)
```

```dart
IbanValidator.getExpectedLength('NO'); // 15 (shortest)
IbanValidator.getExpectedLength('RU'); // 33 (longest)
IbanValidator.getExpectedLength('US'); // null

final sepaCount = IbanValidator.getSepaCountries().length;       // 40
final expCount  = IbanValidator.getExperimentalCountries().length; // 22
```

---

## Error handling patterns

### Simple validation in a service class

```dart
class PaymentService {
  /// Returns null on success, or an error message to show the user.
  String? validateBeneficiaryIban(String iban, String countryCode) {
    final result = IbanValidator.validate(iban, countryCca2: countryCode);
    return result.isValid ? null : result.errorMessage;
  }
}
```

### Throwing on invalid input

```dart
class StrictPaymentProcessor {
  void process(String iban) {
    final result = IbanValidator.validate(iban);
    if (!result.isValid) {
      throw FormatException(
        'Invalid IBAN: ${result.errorMessage}',
        iban,
      );
    }
    // proceed with result.cleanedIban
  }
}
```

### Pattern matching on the error type (Dart 3+)

```dart
String userFriendlyMessage(IbanValidationResult result) {
  if (result.isValid) return 'IBAN looks good!';

  return switch (result.error!) {
    IbanValidationError.emptyInput         => 'Please enter your IBAN.',
    IbanValidationError.tooShort           => 'That IBAN is too short.',
    IbanValidationError.invalidCharacters  => 'IBANs can only contain letters and numbers.',
    IbanValidationError.unknownCountry     => 'We don\'t recognise that country code.',
    IbanValidationError.countryMismatch    => 'The IBAN doesn\'t match the selected country.',
    IbanValidationError.invalidLength      =>
        'A ${result.countryInfo?.countryName ?? ''} IBAN should be '
        '${result.countryInfo?.ibanLength ?? '?'} characters long.',
    IbanValidationError.checksumFailed     => 'Please double-check your IBAN — it looks like there\'s a typo.',
  };
}
```

### Filtering a list of IBANs

```dart
final ibans = [
  'DE89 3704 0044 0532 0130 00',
  'INVALID',
  'GB29 NWBK 6016 1331 9268 19',
  'FR76 3000 6000 0112 3456 7890 189',
];

final valid   = ibans.where(IbanValidator.isValid).toList();
final invalid = ibans.where((i) => !IbanValidator.isValid(i)).toList();
```

---

## How IBAN validation works

An IBAN (International Bank Account Number) is validated using the **ISO 7064 MOD-97-10** algorithm. Here are the five steps:

**1. Clean the input**
Strip all spaces and convert to uppercase. `'de89 3704'` → `'DE893704'`.

**2. Look up the country**
The first two characters are the ISO 3166-1 alpha-2 country code. Check it against the registry and verify the total length matches the country's fixed IBAN length.

**3. Rearrange**
Move the first four characters (country code + check digits) to the end of the string.
`'DE89370400440532013000'` → `'370400440532013000DE89'`

**4. Convert letters to numbers**
Replace every letter with its numeric equivalent: `A=10`, `B=11`, … `Z=35`. This expands letters to two digits each.
`'370400440532013000DE89'` → `'37040044053201300013148 9'`

**5. Compute mod 97**
Interpret the resulting digit string as a large integer and compute its remainder when divided by 97. If the remainder equals **1**, the IBAN is valid.

The digit string can be up to 34 characters long — far too large for a standard integer. This package processes it in 7-digit chunks, carrying the remainder forward, which keeps every intermediate value safely within Dart's native `int` range on all platforms.

```
chunk 1: 3704004 % 97 = 53
chunk 2: 534405320130 → 5344053 % 97 = 10
...
final remainder = 1  →  ✓ valid
```

This algorithm catches every single-character substitution error and virtually all transposition errors — the two most common ways people mistype an IBAN.

---

## Supported countries

### Official ISO 13616 countries (94)

These countries are in the SWIFT IBAN registry (source: [iban.com/structure](https://www.iban.com/structure), updated 30 March 2026).

| Code | Country                | Length | SEPA |
| ---- | ---------------------- | :----: | :--: |
| AD   | Andorra                |   24   |  ✓   |
| AE   | United Arab Emirates   |   23   |      |
| AL   | Albania                |   28   |      |
| AM   | Armenia                |   28   |      |
| AT   | Austria                |   20   |  ✓   |
| AZ   | Azerbaijan             |   28   |      |
| BA   | Bosnia and Herzegovina |   20   |      |
| BE   | Belgium                |   16   |  ✓   |
| BH   | Bahrain                |   22   |      |
| BI   | Burundi                |   27   |      |
| BG   | Bulgaria               |   22   |  ✓   |
| BR   | Brazil                 |   29   |      |
| BY   | Belarus                |   28   |      |
| CH   | Switzerland            |   21   |  ✓   |
| CR   | Costa Rica             |   22   |      |
| CY   | Cyprus                 |   28   |  ✓   |
| CZ   | Czech Republic         |   24   |  ✓   |
| DE   | Germany                |   22   |  ✓   |
| DJ   | Djibouti               |   27   |      |
| DK   | Denmark                |   18   |  ✓   |
| DO   | Dominican Republic     |   28   |      |
| EE   | Estonia                |   20   |  ✓   |
| EG   | Egypt                  |   29   |      |
| ES   | Spain                  |   24   |  ✓   |
| FI   | Finland                |   18   |  ✓   |
| FK   | Falkland Islands       |   18   |      |
| FO   | Faroe Islands          |   18   |      |
| FR   | France                 |   27   |  ✓   |
| GB   | United Kingdom         |   22   |  ✓   |
| GE   | Georgia                |   22   |      |
| GI   | Gibraltar              |   23   |  ✓   |
| GL   | Greenland              |   18   |      |
| GR   | Greece                 |   27   |  ✓   |
| GT   | Guatemala              |   28   |      |
| HN   | Honduras               |   28   |      |
| HR   | Croatia                |   21   |  ✓   |
| HU   | Hungary                |   28   |  ✓   |
| IE   | Ireland                |   22   |  ✓   |
| IL   | Israel                 |   23   |      |
| IQ   | Iraq                   |   23   |      |
| IS   | Iceland                |   26   |  ✓   |
| IT   | Italy                  |   27   |  ✓   |
| JO   | Jordan                 |   30   |      |
| KG   | Kyrgyzstan             |   26   |      |
| KW   | Kuwait                 |   30   |      |
| KZ   | Kazakhstan             |   20   |      |
| LB   | Lebanon                |   28   |      |
| LC   | Saint Lucia            |   32   |      |
| LI   | Liechtenstein          |   21   |  ✓   |
| LT   | Lithuania              |   20   |  ✓   |
| LU   | Luxembourg             |   20   |  ✓   |
| LV   | Latvia                 |   21   |  ✓   |
| LY   | Libya                  |   25   |      |
| MC   | Monaco                 |   27   |  ✓   |
| MD   | Moldova                |   24   |  ✓   |
| ME   | Montenegro             |   22   |  ✓   |
| MK   | North Macedonia        |   19   |  ✓   |
| MN   | Mongolia               |   20   |      |
| MR   | Mauritania             |   27   |      |
| MT   | Malta                  |   31   |  ✓   |
| MU   | Mauritius              |   30   |      |
| NI   | Nicaragua              |   28   |      |
| NL   | Netherlands            |   18   |  ✓   |
| NO   | Norway                 |   15   |  ✓   |
| OM   | Oman                   |   23   |      |
| PK   | Pakistan               |   24   |      |
| PL   | Poland                 |   28   |  ✓   |
| PS   | Palestine              |   29   |      |
| PT   | Portugal               |   25   |  ✓   |
| QA   | Qatar                  |   29   |      |
| RO   | Romania                |   24   |  ✓   |
| RS   | Serbia                 |   22   |  ✓   |
| RU   | Russia                 |   33   |      |
| SA   | Saudi Arabia           |   24   |      |
| SC   | Seychelles             |   31   |      |
| SD   | Sudan                  |   18   |      |
| SE   | Sweden                 |   24   |  ✓   |
| SI   | Slovenia               |   19   |  ✓   |
| SK   | Slovakia               |   24   |  ✓   |
| SM   | San Marino             |   27   |  ✓   |
| SO   | Somalia                |   23   |      |
| ST   | Sao Tome and Principe  |   25   |      |
| SV   | El Salvador            |   28   |      |
| TJ   | Tajikistan             |   22   |      |
| TL   | Timor-Leste            |   23   |      |
| TM   | Turkmenistan           |   26   |      |
| TN   | Tunisia                |   24   |      |
| TR   | Turkey                 |   26   |      |
| UA   | Ukraine                |   29   |      |
| UZ   | Uzbekistan             |   28   |      |
| VA   | Vatican City           |   22   |  ✓   |
| VG   | British Virgin Islands |   24   |      |
| XK   | Kosovo                 |   20   |      |
| YE   | Yemen                  |   30   |      |

### Experimental / partial IBAN countries (22)

These countries have adopted an IBAN-like format locally but are **not yet registered** in the official ISO 13616 SWIFT registry. Their formats may change. In code, these entries have `isExperimental: true`.

> **Note:** Use experimental IBANs with care in production systems. Always tell your users if a country is experimental.

| Code | Country                  | Length |
| ---- | ------------------------ | :----: |
| AO   | Angola                   |   25   |
| BF   | Burkina Faso             |   28   |
| BJ   | Benin                    |   28   |
| CF   | Central African Republic |   27   |
| CG   | Congo                    |   27   |
| CI   | Ivory Coast              |   28   |
| CM   | Cameroon                 |   27   |
| CV   | Cape Verde               |   25   |
| DZ   | Algeria                  |   24   |
| GA   | Gabon                    |   27   |
| GQ   | Equatorial Guinea        |   27   |
| GW   | Guinea-Bissau            |   25   |
| IR   | Iran                     |   26   |
| KM   | Comoros                  |   27   |
| MA   | Morocco                  |   28   |
| MG   | Madagascar               |   27   |
| ML   | Mali                     |   28   |
| MZ   | Mozambique               |   25   |
| NE   | Niger                    |   28   |
| SN   | Senegal                  |   28   |
| TD   | Chad                     |   27   |
| TG   | Togo                     |   28   |

---

## Contributing

Contributions are welcome — especially updates to the country registry.

**To add or update a country:**

1. Edit [`lib/src/iban_data.dart`](lib/src/iban_data.dart) with the new or corrected `IbanCountryInfo` entry.
2. Add a corresponding test case in [`test/iban_validator_test.dart`](test/iban_validator_test.dart).
3. Run `dart test` to confirm all tests pass.
4. Open a pull request.

**Registry source:** [iban.com/structure](https://www.iban.com/structure) (updated 30 March 2026).

**Reporting bugs:** Please open an issue at [github.com/khrisbreezy/iban_validator/issues](https://github.com/khrisbreezy/iban_validator/issues) and include the IBAN (or a fake one with the same structure), the country, and what result you expected vs what you got.

---

## License

[MIT](LICENSE) © 2026 Oyinlola Abolarin
