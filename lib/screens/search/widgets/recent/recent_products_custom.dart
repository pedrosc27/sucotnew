import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants.dart';
import '../../../../generated/l10n.dart';
import '../../../../models/search_model.dart';
import '../../../../modules/dynamic_layout/config/product_config.dart';
import '../../../../services/index.dart';

class RecentProductsCustom extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var screenWidth = constraints.maxWidth;

        return Consumer<SearchModel>(builder: (context, model, child) {
          if (model.products?.isEmpty ?? true) {
            return const SizedBox();
          }

          return Container();
        });
      },
    );
  }
}
