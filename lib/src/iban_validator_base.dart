import 'iban_data.dart';

/// The outcome of an IBAN validation check.
enum IbanValidationError {
  emptyInput,
  tooShort,
  unknownCountry,
  countryMismatch,
  invalidLength,
  invalidCharacters,
  checksumFailed,
}

/// The result returned by [IbanValidator.validate].
class IbanValidationResult {
  /// Whether the IBAN passed all validation checks.
  final bool isValid;

  /// The IBAN with spaces stripped and letters uppercased.
  final String cleanedIban;

  /// The validation error, or `null` when [isValid] is `true`.
  final IbanValidationError? error;

  /// A human-readable description of [error], or `null` when valid.
  final String? errorMessage;

  /// Metadata for the IBAN's country, when the country code is recognised.
  final IbanCountryInfo? countryInfo;

  const IbanValidationResult._({
    required this.isValid,
    required this.cleanedIban,
    this.error,
    this.errorMessage,
    this.countryInfo,
  });

  factory IbanValidationResult._valid({
    required String cleanedIban,
    required IbanCountryInfo countryInfo,
  }) =>
      IbanValidationResult._(
        isValid: true,
        cleanedIban: cleanedIban,
        countryInfo: countryInfo,
      );

  factory IbanValidationResult._invalid({
    required String cleanedIban,
    required IbanValidationError error,
    required String errorMessage,
    IbanCountryInfo? countryInfo,
  }) =>
      IbanValidationResult._(
        isValid: false,
        cleanedIban: cleanedIban,
        error: error,
        errorMessage: errorMessage,
        countryInfo: countryInfo,
      );

  @override
  String toString() => isValid
      ? 'IbanValidationResult(valid, $cleanedIban, ${countryInfo?.countryName})'
      : 'IbanValidationResult(invalid, $cleanedIban, $error: $errorMessage)';
}

/// Validates International Bank Account Numbers (IBAN) per ISO 13616.
abstract class IbanValidator {
  IbanValidator._();

  /// Returns `true` if [iban] is a structurally valid IBAN.
  /// Spaces are stripped and the string is uppercased automatically.
  /// If [countryCca2] is provided the IBAN country code must match it.
  static bool isValid(String iban, {String? countryCca2}) =>
      validate(iban, countryCca2: countryCca2).isValid;

  /// Returns a detailed [IbanValidationResult].
  static IbanValidationResult validate(String iban, {String? countryCca2}) {
    final clean = iban.replaceAll(' ', '').toUpperCase();

    if (clean.isEmpty) {
      return IbanValidationResult._invalid(
        cleanedIban: clean,
        error: IbanValidationError.emptyInput,
        errorMessage: 'The input string is empty.',
      );
    }

    if (clean.length < 4) {
      return IbanValidationResult._invalid(
        cleanedIban: clean,
        error: IbanValidationError.tooShort,
        errorMessage: 'An IBAN must be at least 4 characters long.',
      );
    }

    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(clean)) {
      return IbanValidationResult._invalid(
        cleanedIban: clean,
        error: IbanValidationError.invalidCharacters,
        errorMessage:
            'IBANs may only contain the letters A–Z and the digits 0–9.',
      );
    }

    final countryCode = clean.substring(0, 2);
    final info = kIbanRegistry[countryCode];

    if (info == null) {
      return IbanValidationResult._invalid(
        cleanedIban: clean,
        error: IbanValidationError.unknownCountry,
        errorMessage: '"$countryCode" is not a recognised IBAN country code.',
      );
    }

    if (countryCca2 != null && countryCode != countryCca2.toUpperCase()) {
      return IbanValidationResult._invalid(
        cleanedIban: clean,
        error: IbanValidationError.countryMismatch,
        errorMessage:
            'Expected country "$countryCca2" but the IBAN starts with "$countryCode".',
        countryInfo: info,
      );
    }

    if (clean.length != info.ibanLength) {
      return IbanValidationResult._invalid(
        cleanedIban: clean,
        error: IbanValidationError.invalidLength,
        errorMessage:
            '${info.countryName} IBANs must be exactly ${info.ibanLength} '
            'characters long (got ${clean.length}).',
        countryInfo: info,
      );
    }

    if (_mod97(clean) != 1) {
      return IbanValidationResult._invalid(
        cleanedIban: clean,
        error: IbanValidationError.checksumFailed,
        errorMessage: 'The mod-97 checksum failed. The IBAN contains an error.',
        countryInfo: info,
      );
    }

    return IbanValidationResult._valid(cleanedIban: clean, countryInfo: info);
  }

  /// Returns a sorted, unmodifiable list of all supported country codes.
  static List<String> getSupportedCountries() {
    final codes = kIbanRegistry.keys.toList()..sort();
    return List.unmodifiable(codes);
  }

  /// Returns [IbanCountryInfo] for [countryCode] (case-insensitive), or null.
  static IbanCountryInfo? getCountryInfo(String countryCode) =>
      kIbanRegistry[countryCode.toUpperCase()];

  /// Returns all SEPA countries sorted by country code.
  static List<IbanCountryInfo> getSepaCountries() {
    return kIbanRegistry.values.where((c) => c.isSepa).toList()
      ..sort((a, b) => a.countryCode.compareTo(b.countryCode));
  }

  /// Returns all non-SEPA countries sorted by country code.
  static List<IbanCountryInfo> getNonSepaCountries() {
    return kIbanRegistry.values.where((c) => !c.isSepa).toList()
      ..sort((a, b) => a.countryCode.compareTo(b.countryCode));
  }

  /// Returns all experimental / partial-IBAN countries.
  static List<IbanCountryInfo> getExperimentalCountries() {
    return kIbanRegistry.values.where((c) => c.isExperimental).toList()
      ..sort((a, b) => a.countryCode.compareTo(b.countryCode));
  }

  /// Returns the expected IBAN length for [countryCode], or null if unsupported.
  static int? getExpectedLength(String countryCode) =>
      kIbanRegistry[countryCode.toUpperCase()]?.ibanLength;

  // ── Private ──────────────────────────────────────────────────────────────

  static int _mod97(String iban) {
    final rearranged = iban.substring(4) + iban.substring(0, 4);
    final buffer = StringBuffer();
    for (final char in rearranged.split('')) {
      final unit = char.codeUnitAt(0);
      if (unit >= 65 && unit <= 90) {
        buffer.write(unit - 55);
      } else {
        buffer.write(char);
      }
    }
    final numeric = buffer.toString();
    var remainder = '';
    var i = 0;
    while (i < numeric.length) {
      final end = (i + 7).clamp(0, numeric.length);
      final part = remainder + numeric.substring(i, end);
      remainder = (int.parse(part) % 97).toString();
      i += 7;
    }
    return int.parse(remainder);
  }
}
