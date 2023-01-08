import 'package:flutter/material.dart';
import 'package:fstore/common/tools.dart';
import 'package:fstore/common/tools/price_tools.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart';
import '../../common/tools/adaptive_tools.dart';
import '../../../services/index.dart';
import '../../../models/index.dart' show AppModel;
import '../../models/index.dart' show CartModel, Product;
import '../../modules/dynamic_layout/config/product_config.dart';
import 'action_button_mixin.dart';
import 'index.dart'
    show
        CartButton,
        CartIcon,
        CartQuantity,
        HeartButton,
        ProductImage,
        ProductOnSale,
        ProductPricing,
        ProductRating,
        ProductTitle,
        SaleProgressBar,
        StockStatus,
        StoreName;
import 'widgets/cart_button_with_quantity.dart';

class ProductCard extends StatefulWidget {
  final Product item;
  final double? width;
  final double? maxWidth;
  final bool hideDetail;
  final offset;
  final ProductConfig config;
  final onTapDelete;

  const ProductCard({
    required this.item,
    this.width,
    this.maxWidth,
    this.offset,
    this.hideDetail = false,
    required this.config,
    this.onTapDelete,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with ActionButtonMixin {
  int _quantity = 1;
  
  @override
  Widget build(BuildContext context) {
        final currency = Provider.of<AppModel>(context).currency; 
    final currencyRates = Provider.of<CartModel>(context).currencyRates;
    final currencyRate = Provider.of<AppModel>(context).currencyRate;
        var isSale = (widget.item.onSale ?? false) &&
        PriceTools.getPriceProductValue(widget.item, currency, onSale: true) !=
            PriceTools.getPriceProductValue(widget.item, currency, onSale: false);

    var priceProduct = PriceTools.getPriceProduct(widget.item, currencyRate, currency,
        onSale: isSale)!;
    /// use for Staged layout
    if (widget.hideDetail) {
      return ProductImage(
        width: widget.width!,
        product: widget.item,
        config: widget.config,
        ratioProductImage: widget.config.imageRatio,
        offset: widget.offset,
        onTapProduct: () => onTapProduct(context, product: widget.item),
      );
    }

 

    return Container(
       padding: const EdgeInsets.all(4),
      child: GestureDetector(
        onTap: () => onTapProduct(context, product: widget.item),
        child: Container(
          decoration: BoxDecoration(
              color: const Color(0xFFEDEDED), borderRadius: BorderRadius.circular(15)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
    
           //Image.network(widget.item.imageFeature.toString()),
           
                ProductImage(
                          width: 120,
                          product: widget.item,
                          config: widget.config,
                          ratioProductImage: 0.8,
                          offset: widget.offset,
                          onTapProduct: () =>
                              onTapProduct(context, product: widget.item),
                        ),

              const SizedBox(
                height: 8,
              ),
              Text(
                widget.item.name.toString(),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: 'NeoRegular',
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                priceProduct,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFFcc0000),
                    fontFamily: 'NeoRegular',
                    fontWeight: FontWeight.w700),
              ),
                     
              //Services().widget.renderDetailPrice(context, widget.item, priceProduct),
            ],
          ),
          
        ),
      ),
    );
  }
}
