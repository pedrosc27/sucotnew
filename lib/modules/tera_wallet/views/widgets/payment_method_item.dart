import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/config.dart';
import '../../../../common/tools/price_tools.dart';
import '../../../../generated/l10n.dart';
import '../../../../models/index.dart' show AppModel, PaymentMethod;
import '../../../../models/tera_wallet/wallet_model.dart';
import '../../../../screens/checkout/widgets/payment_method_item.dart' as base;
import 'warning_currency.dart';

class PaymentMethodItem extends StatelessWidget {
  const PaymentMethodItem({Key? key, required this.paymentMethod, required this.onSelected, this.selectedId, this.descWidget}) : super(key: key);
  final PaymentMethod paymentMethod;
  final Function(String?) onSelected;
  final String? selectedId;
  final Widget? descWidget;

  @override
  Widget build(BuildContext context) {
    final currency = Provider.of<AppModel>(context, listen: false).currency;
    final defaultCurrency = (kAdvanceConfig['DefaultCurrency'] as Map)['currencyCode'];
    final disablePayment = defaultCurrency.toString().toLowerCase() != currency.toString().toLowerCase();
    return Consumer<WalletModel>(builder: (context, model, child) {
      if(model.balance > 0){
        return base.PaymentMethodItem(paymentMethod: paymentMethod, onSelected: disablePayment ? null : onSelected, selectedId: selectedId, descWidget: disablePayment ? WarningCurrency(defaultCurrency: defaultCurrency) : CurrentBalance(balance: model.balance));
      }else{
        return const SizedBox();
      }
    });
  }
}

class CurrentBalance extends StatelessWidget {
  const CurrentBalance({Key? key, required this.balance}) : super(key: key);
  final double balance;

  @override
  Widget build(BuildContext context) {
    final currency = Provider.of<AppModel>(context, listen: false).currency;
    final currencyRate = Provider.of<AppModel>(context, listen: false).currencyRate;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorLight,
        borderRadius: const BorderRadius.all(
          Radius.circular(6),
        ),
      ),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0), child: Text(S.of(context).balance+': '+PriceTools.getCurrencyFormatted(balance, currencyRate,
          currency: currency)!),),
    );
  }
}