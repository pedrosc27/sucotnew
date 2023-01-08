import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../models/entities/index.dart' show AddonsOption;
import '../../models/index.dart' show AppModel, Product, ProductVariation;
import '../../services/index.dart';
import 'widgets/quantity_selection.dart';

class ShoppingCartRow extends StatelessWidget {
  const ShoppingCartRow({
    required this.product,
    required this.quantity,
    this.onRemove,
    this.onChangeQuantity,
    this.variation,
    this.options,
    this.addonsOptions,
  });

  final Product? product;
  final List<AddonsOption>? addonsOptions;
  final ProductVariation? variation;
  final Map<String, dynamic>? options;
  final int? quantity;
  final Function? onChangeQuantity;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    var currency = Provider.of<AppModel>(context).currency;
    final currencyRate = Provider.of<AppModel>(context).currencyRate;

    final price = Services().widget.getPriceItemInCart(
        product!, variation, currencyRate, currency,
        selectedOptions: addonsOptions);
    final imageFeature = variation != null && variation!.imageFeature != null
        ? variation!.imageFeature
        : product!.imageFeature;
    var maxQuantity = kCartDetail['maxAllowQuantity'] ?? 100;
    var totalQuantity = variation != null
        ? (variation!.stockQuantity ?? maxQuantity)
        : (product!.stockQuantity ?? maxQuantity);
    var limitQuantity =
        totalQuantity > maxQuantity ? maxQuantity : totalQuantity;

    var theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                key: ValueKey(product!.id),
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
  
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          color: const Color(0xFFEDEDED),
                          child: SizedBox(
                            width: constraints.maxWidth * 0.25,
                            height: constraints.maxWidth * 0.3,
                            child: ImageTools.image(url: imageFeature),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  product!.name!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontFamily: 'NeoRegular', 
                                    fontWeight: FontWeight.w700),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  price!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontFamily: 'NeoRegular')
                                ),
                                const SizedBox(height: 10),
                                if (product!.options != null && options != null)
                                  Services()
                                      .widget
                                      .renderOptionsCartItem(product!, options),
                                if (variation != null)
                                  Services().widget.renderVariantCartItem(
                                      context, variation!, options),
                                if (addonsOptions?.isNotEmpty ?? false)
                                  Services().widget.renderAddonsOptionsCartItem(
                                      context, addonsOptions),
                                if (kProductDetail.showStockQuantity)
                                  QuantitySelection(
                                    enabled: onChangeQuantity != null,
                                    width: 60,
                                    height: 32,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    limitSelectQuantity: limitQuantity,
                                    value: quantity,
                                    onChanged: onChangeQuantity,
                                    useNewDesign: false,
                                  ),
                                if (product?.store != null &&
                                    (product?.store?.name != null &&
                                        product!.store!.name!.trim().isNotEmpty))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5.0),
                                    child: Text(
                                      product!.store!.name!,
                                      style: TextStyle(
                                          color: theme.colorScheme.secondary,
                                          fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (onRemove != null)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Color(0xFFcc0000),),
                      onPressed: onRemove,
                    ),
                  
                ],
              ),
              const SizedBox(height: 10.0),
              const Divider(color: kGrey200, height: 1),
              const SizedBox(height: 10.0),
            ],
          ),
        );
      },
    );
  }
}
