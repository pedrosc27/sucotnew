import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/constants.dart';
import '../../../common/tools.dart';
import '../../../generated/l10n.dart';
import '../../../models/category_model.dart';
import '../../../models/entities/back_drop_arguments.dart';
import '../../../routes/flux_navigate.dart';
import '../config/index.dart';
import 'common_item_extension.dart';

/// The category icon circle list
class CategoryImageItem extends StatelessWidget {
  final CategoryItemConfig config;
  final products;
  final width;
  final height;
  final CommonItemConfig commonConfig;

  const CategoryImageItem({
    required this.config,
    this.products,
    this.width,
    this.height,
    required this.commonConfig,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final itemWidth = (width ?? screenSize.width) / 3;
    final categoryList = Provider.of<CategoryModel>(context).categoryList;

    final id = config.category.toString();
    final name = categoryList[id] != null ? categoryList[id]!.name : '';
    final image = categoryList[id] != null ? categoryList[id]!.image : '';
    final  imagenFinal = image.toString();
    final total =
        categoryList[id] != null ? categoryList[id]!.totalProduct : '';

    final imageWidget = config.image != null
        ? config.image.toString().contains('http')
            ? ImageTools.image(
                url: config.image ?? '',
                fit: commonConfig.boxFit,
              )
            : Image.asset(
                config.image!,
                fit: commonConfig.boxFit,
              )
        : null;
    final border = commonConfig.enableBorder ? (commonConfig.border ?? 0.5) : 0;

    return InkWell(
      onTap: () {
        FluxNavigate.pushNamed(
          RouteList.backdrop,
          arguments: BackDropArguments(
            config: config.toJson(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 15.0),
                width: 150,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: const Color(0xffEDEDED), borderRadius: BorderRadius.circular(15)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    
                    Image.asset(
                      config.image!,
                      width: 100,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                        config.name ?? config.title ?? name!,
                         style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontFamily: 'NeoRegular',
                          fontWeight: FontWeight.w700),
                      ),
                  ],
                ),
              ),
    );
  }
}
