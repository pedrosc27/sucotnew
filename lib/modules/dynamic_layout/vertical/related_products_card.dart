import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../common/tools.dart';
import '../../../models/index.dart' show CartModel, Product;
import '../../../services/service_config.dart';
import '../../../widgets/common/start_rating.dart';
import '../../../widgets/product/index.dart';
import '../config/product_config.dart';
import '../helper/helper.dart';

class RelatedProductsCard extends StatelessWidget {
  final Product item;
  final width;
  final marginRight;
  final kSize size;
  final ProductConfig config;

  const RelatedProductsCard(
      {required this.item,
      this.width,
      this.size = kSize.medium,
      this.marginRight = 10.0,
      required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addProductToCart = Provider.of<CartModel>(context).addProductToCart;
    final currency = Provider.of<CartModel>(context).currency;
    final currencyRates = Provider.of<CartModel>(context).currencyRates;
    final isTablet = Helper.isTablet(MediaQuery.of(context));

    var titleFontSize = isTablet ? 24.0 : 14.0;
    var iconSize = isTablet ? 24.0 : 18.0;
    var starSize = isTablet ? 20.0 : 10.0;
    var _showCart = config.showCartIcon && kEnableShoppingCart;
    

    var isSale = (item.onSale ?? false) &&
        PriceTools.getPriceProductValue(item, currency, onSale: true) !=
            PriceTools.getPriceProductValue(item, currency, onSale: false);

    var priceProduct = PriceTools.getPriceProduct(item, currencyRates, currency,
        onSale: isSale)!;

    void onTapProduct() {
      if (item.imageFeature == '') return;
      Navigator.of(context).pushNamed(
        RouteList.productDetail,
        arguments: item,
      );
    }

    return Container(
      width: 200,
       padding: const EdgeInsets.all(4),
      child: GestureDetector(
        onTap: onTapProduct,
        child: Container(
          decoration: BoxDecoration(
              color: const Color(0xFFEDEDED), borderRadius: BorderRadius.circular(15)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
    
             
            Image.network(item.imageFeature!, width: 120,),
              
              const SizedBox(
                height: 8,
              ),
              Text(
                item.name!,
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
              const SizedBox(
                height: 8,
              ),
              
            ],
          ),
          
        ),
      ),
    );
  }
}
