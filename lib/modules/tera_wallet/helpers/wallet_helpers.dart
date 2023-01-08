import 'package:intl/intl.dart';

import '../../../common/config.dart';

class WalletHelpers {
  static final _defaultCurrency = kAdvanceConfig['DefaultCurrency'];
  static final _numberFormat = NumberFormat.currency(
    locale: kAdvanceConfig['DefaultLanguage'],
    name: _defaultCurrency['currency'],
    symbol: _defaultCurrency['symbol'],
    decimalDigits: _defaultCurrency['decimalDigits'],
  );

  static double parseSymbolNumberToNumber(String currencyText) {
    return double.parse(currencyText
        .replaceAll(_numberFormat.symbols.GROUP_SEP, '')
        .replaceAll(_numberFormat.currencySymbol, ''));
  }

  static String parseNumberToCurrencyText(double number) {
    return _numberFormat.format(number);
  }

  static NumberFormat get numberFormat => _numberFormat;
}
