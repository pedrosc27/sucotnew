import 'package:flutter/material.dart';

import '../../../models/index.dart' show Product;
import '../../../widgets/html/index.dart' as html;

class ProductShortDescription extends StatelessWidget {
  final Product product;

  const ProductShortDescription(this.product);

  @override
  Widget build(BuildContext context) {
    if (product.shortDescription?.isEmpty ?? true) {
      return const SizedBox();
    }

    return Container(
      
    );
  }
}
