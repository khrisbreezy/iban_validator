# Changelog

## 1.0.1

- Shortened package description to comply with pub.dev requirements.

## 1.0.0

- Initial release.
- Full ISO 13616 / SWIFT IBAN registry support (89 official countries).
- Experimental support for 22 partial-IBAN countries (mostly Africa).
- `IbanValidator.isValid()` — simple boolean check.
- `IbanValidator.validate()` — detailed `IbanValidationResult` with typed error enum.
- `IbanValidator.getSupportedCountries()` — sorted, unmodifiable list.
- `IbanValidator.getCountryInfo()` — per-country metadata.
- `IbanValidator.getSepaCountries()` / `getNonSepaCountries()` / `getExperimentalCountries()`.
- `IbanValidator.getExpectedLength()` — fixed IBAN length by country.
- Chunked mod-97 — safe on all Dart platforms, no BigInt required.
- Dart SDK ≥ 3.0.0.
