/// A comprehensive IBAN validator for Dart and Flutter.
///
/// Supports all 89 countries in the official ISO 13616 / SWIFT IBAN registry
/// plus 22 experimental countries, totalling 111 country codes.
library;

export 'src/iban_data.dart' show IbanCountryInfo, kIbanRegistry;
export 'src/iban_validator_base.dart'
    show IbanValidationError, IbanValidationResult, IbanValidator;
