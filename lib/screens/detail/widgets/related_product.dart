import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../generated/l10n.dart';
import '../../../models/index.dart' show AppModel, Product;
import '../../../modules/dynamic_layout/config/product_config.dart';
import '../../../modules/dynamic_layout/vertical/related_products_card.dart';
import '../../../services/index.dart';
import '../../../widgets/product/product_card_view.dart';

class RelatedProduct extends StatefulWidget {
  final Product? product;

  const RelatedProduct(this.product);

  @override
  _RelatedProductState createState() => _RelatedProductState();
}

class _RelatedProductState extends State<RelatedProduct> {
  final _memoizer = AsyncMemoizer<List<Product>?>();

  final services = Services();

  Future<List<Product>?> getRelativeProducts(context) => _memoizer.runOnce(() {
        return services.api.fetchProductsByCategory(
            page: 1,
            categoryId: widget.product!.categoryId,
            include: widget.product?.relatedIds,
            lang: Provider.of<AppModel>(context).langCode);
      });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraint) {
        return FutureBuilder<List<Product>?>(
          future: getRelativeProducts(context),
          builder:
              (BuildContext context, AsyncSnapshot<List<Product>?> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.active:
              case ConnectionState.waiting:
                return SizedBox(
                  height: 100,
                  child: kLoadingWidget(context),
                );
              case ConnectionState.done:
                if (snapshot.hasError) {
                  return SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        S.of(context).error(snapshot.error!),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary),
                      ),
                    ),
                  );
                } else if (snapshot.data!.isEmpty) {
                  return const SizedBox();
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding:  EdgeInsets.symmetric(
                          vertical: 18.0,
                          horizontal: 16.0,
                        ),
                        child: Text(
                          'Productos Relacionados',
                            style:  TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontFamily: 'NeoRegular',
                            fontWeight: FontWeight.w700),
                        ),
                      ),
                      SizedBox(
                        height: 200,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          cacheExtent: MediaQuery.of(context).size.width,
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (var item in snapshot.data!)
                              if (item.id != widget.product!.id)
                              RelatedProductsCard(item: item, config: ProductConfig.empty())
                               
                                
                          ],
                        ),
                      ),
                      const SizedBox(height: 70),
                    ],
                  );
                }
            }
          },
        );
      },
    );
  }
}
