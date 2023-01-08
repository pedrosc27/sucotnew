import 'package:flutter/material.dart';
import 'package:inspireui/widgets/expandable/expansion_widget.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../generated/l10n.dart';
import '../../models/index.dart'
    show AppModel, BlogModel, FilterAttributeModel, ProductModel;
import '../../services/service_config.dart';
import 'filters/category_menu.dart';
import 'filters/container_filter.dart';
import 'filters/filter_option_item.dart';
import 'filters/listing_menu.dart';
import 'filters/tag_menu.dart';

class BackdropMenu extends StatefulWidget {
  final Function({
    dynamic minPrice,
    dynamic maxPrice,
    String? categoryId,
    String? categoryName,
    String? tagId,
    dynamic attribute,
    dynamic currentSelectedTerms,
    dynamic listingLocationId,
  })? onFilter;
  final String? categoryId;
  final String? tagId;
  final String? listingLocationId;
  final bool showCategory;
  final bool showPrice;
  final bool isUseBlog;
  final ScrollController? controller;
  final double? minPrice;
  final double? maxPrice;

  const BackdropMenu({
    Key? key,
    this.onFilter,
    this.categoryId,
    this.tagId,
    this.showCategory = true,
    this.showPrice = true,
    this.isUseBlog = false,
    this.listingLocationId,
    this.controller,
    this.minPrice,
    this.maxPrice,
  }) : super(key: key);

  @override
  _BackdropMenuState createState() => _BackdropMenuState();
}

class _BackdropMenuState extends State<BackdropMenu> {
  double minPrice = 0.0;
  double maxPrice = 0.0;
  String? currentSlug;
  int currentSelectedAttr = -1;
  String? _categoryId = '-1';

  String? get currency => Provider.of<AppModel>(context).currency;
  Map<String, dynamic> get currencyRate =>
      Provider.of<AppModel>(context, listen: false).currencyRate;
  String get selectLayout =>
      Provider.of<AppModel>(context, listen: false).productListLayout;
  FilterAttributeModel get filterAttr =>
      Provider.of<FilterAttributeModel>(context, listen: false);

  ProductModel get productModel =>
      Provider.of<ProductModel>(context, listen: false);

  String? get categoryId =>
      _categoryId ??
      Provider.of<ProductModel>(context, listen: false).categoryId;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.categoryId;
    minPrice = widget.minPrice ?? 0;
    maxPrice = widget.maxPrice ?? 0;

    /// Support loading Blog Category inside Woo/Vendor config
    if (widget.isUseBlog) {
      Provider.of<BlogModel>(context, listen: false).getCategoryList();

      /// enable if using Tag, otherwise disable to save performance
      // Provider.of<BlogModel>(context, listen: false).getTagList();
    }
  }

  void _onFilter({
    String? categoryId,
    String? categoryName,
    String? tagId,
    listingLocationId,
  }) =>
      widget.onFilter!(
        minPrice: minPrice,
        maxPrice: maxPrice,
        categoryId: categoryId,
        categoryName: categoryName ?? '',
        tagId: tagId,
        attribute: currentSlug,
        listingLocationId: listingLocationId ??
            Provider.of<ProductModel>(context, listen: false).listingLocationId,
      );

 

  Widget renderPriceSlider() {
    var primaryColor = kAdvanceConfig['enableProductBackdrop'] ?? false
        ? Colors.white
        : Theme.of(context).primaryColor;

    return ExpansionWidget(
      showDivider: true,
      padding: const EdgeInsets.only(
        left: 15,
        right: 15,
        top: 15,
        bottom: 10,
      ),
      title: Text(
        S.of(context).byPrice,
        style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (minPrice != 0 || maxPrice != 0) ...[
              Text(
                PriceTools.getCurrencyFormatted(minPrice, currencyRate,
                    currency: currency)!,
                style: Theme.of(context).textTheme.headline6,
              ),
              Text(
                ' - ',
                style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.secondary),
              ),
            ],
            Text(
              PriceTools.getCurrencyFormatted(maxPrice, currencyRate,
                  currency: currency)!,
              style: Theme.of(context).textTheme.headline6,
            )
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: primaryColor,
            inactiveTrackColor:
                Theme.of(context).primaryColorLight.withOpacity(0.5),
            activeTickMarkColor: Theme.of(context).primaryColorLight,
            inactiveTickMarkColor:
                Theme.of(context).colorScheme.secondary.withOpacity(0.5),
            overlayColor: primaryColor.withOpacity(0.2),
            thumbColor: primaryColor,
            showValueIndicator: ShowValueIndicator.always,
          ),
          child: RangeSlider(
            min: 0.0,
            max: kMaxPriceFilter,
            divisions: kFilterDivision,
            values: RangeValues(minPrice, maxPrice),
            onChanged: (RangeValues values) {
              setState(() {
                minPrice = values.start;
                maxPrice = values.end;
              });

              productModel.setPrices(min: values.start, max: values.end);
            },
          ),
        ),
      ],
    );
  }

  Widget renderAttributes() {
    return ListenableProvider.value(
      value: filterAttr,
      child: Consumer<FilterAttributeModel>(
        builder: (context, value, child) {
          if (value.lstProductAttribute?.isNotEmpty ?? false) {
            var list = List<Widget>.generate(
              value.lstProductAttribute!.length,
              (index) {
                return FilterOptionItem(
                  enabled: !value.isLoading,
                  onTap: () {
                    currentSelectedAttr = index;

                    currentSlug = value.lstProductAttribute![index].slug;
                    value.getAttr(id: value.lstProductAttribute![index].id);
                  },
                  title: value.lstProductAttribute![index].name!.toUpperCase(),
                  isValid: currentSelectedAttr != -1,
                  selected: currentSelectedAttr == index,
                );
              },
            );
            return ExpansionWidget(
              showDivider: true,
              padding: const EdgeInsets.only(
                left: 15,
                right: 15,
                top: 15,
                bottom: 10,
              ),
              title: Text(
                S.of(context).attributes,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      height: list.length > 4 ? 100 : 50,
                      margin: const EdgeInsets.only(left: 10.0),
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: GridView.count(
                        scrollDirection: Axis.horizontal,
                        childAspectRatio: 0.4,
                        shrinkWrap: true,
                        crossAxisCount: list.length > 4 ? 2 : 1,
                        children: list,
                      ),
                    ),
                    value.isLoading
                        ? Center(
                            child: Container(
                              margin: const EdgeInsets.only(
                                top: 10.0,
                              ),
                              width: 25.0,
                              height: 25.0,
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2.0),
                            ),
                          )
                        : Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: currentSelectedAttr == -1
                                ? Container()
                                : Wrap(
                                    children: List.generate(
                                      value.lstCurrentAttr.length,
                                      (index) {
                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 5),
                                          child: FilterChip(
                                            selectedColor:
                                                Theme.of(context).primaryColor,
                                            backgroundColor: Theme.of(context)
                                                .primaryColorLight
                                                .withOpacity(0.3),
                                            label: Text(value
                                                .lstCurrentAttr[index].name!),
                                            selected: value
                                                .lstCurrentSelectedTerms[index],
                                            onSelected: (val) {
                                              value.updateAttributeSelectedItem(
                                                  index, val);
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                  ],
                )
              ],
            );
          }
          return Container();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.controller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (isDisplayDesktop(context))
            SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () {
                      if (isDisplayDesktop(context)) {
                        eventBus.fire(const EventOpenCustomDrawer());
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Icon(Icons.arrow_back_ios,
                        size: 22, color: Colors.white70),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    Config().isWordPress
                        ? context.select((BlogModel _) => _.categoryName) ??
                            S.of(context).blog
                        : S.of(context).products,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

         

          if (Config().isListingType) BackDropListingMenu(onFilter: _onFilter),

          if (!Config().isListingType &&
              Config().type != ConfigType.shopify &&
              widget.showPrice) ...[
            renderAttributes(),
          ],

          /// filter by tags
          widget.isUseBlog ? const SizedBox() : const BackDropTagMenu(),

          if (widget.showCategory)
            CategoryMenu(
              isUseBlog: widget.isUseBlog,
              onFilter: (category) => _onFilter(
                categoryId: category.id,
                categoryName: category.name,
              ),
            ),

          /// render Apply button
          if (!Config().isListingType &&
              (kAdvanceConfig['enableProductBackdrop'] ?? false))
            Container(
             
              padding: const EdgeInsets.only(
                left: 15,
                right: 15,
                top: 5,
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    
                    width: double.infinity,
                   height: 50,
                    child: ButtonTheme(
                      
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0.0,
                          primary: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                        ),
                        onPressed: () {
                          _onFilter(
                            categoryId: categoryId,
                            tagId: Provider.of<ProductModel>(context,
                                    listen: false)
                                .tagId
                                .toString(),
                          );
                        },
                        child: Text(
                          S.of(context).apply,
                          style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'NeoRegular',
                    fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 100,
                  )
                ],
              ),
            ),

          const SizedBox(height:200),
        ],
      ),
    );
  }
}
