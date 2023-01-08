import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../generated/l10n.dart';
import '../../models/index.dart'
    show
        AppModel,
        Category,
        CategoryModel,
        FilterAttributeModel,
        Product,
        ProductModel,
        TagModel,
        UserModel;
import '../../modules/dynamic_layout/helper/countdown_timer.dart';
import '../../modules/dynamic_layout/index.dart';
import '../../services/index.dart';
import '../../widgets/asymmetric/asymmetric_view.dart';
import '../../widgets/backdrop/backdrop.dart';
import '../../widgets/backdrop/backdrop_menu.dart';
import '../../widgets/common/flux_image.dart';
import '../../widgets/product/product_bottom_sheet.dart';
import '../../widgets/product/product_list.dart';
import 'products_backdrop.dart';
import 'products_flatview.dart';

class FilterLabel extends StatelessWidget {
  final String label;
  final Function()? onTap;

  const FilterLabel({Key? key, required this.label, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        constraints: const BoxConstraints(minWidth: 50),
        height: 25,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: Theme.of(context).primaryColor, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.caption,
          ),
        ),
      ),
    );
  }
}

class ProductsScreen extends StatefulWidget {
  final List<Product>? products;
  final ProductConfig? config;
  final Duration countdownDuration;
  final String? listingLocation;

  const ProductsScreen(
      {this.products,
      this.countdownDuration = Duration.zero,
      this.listingLocation,
      this.config});

  @override
  State<StatefulWidget> createState() {
    return ProductsScreenState();
  }
}

class ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  ProductConfig get productConfig => widget.config ?? ProductConfig.empty();

  CategoryModel get categoryModel =>
      Provider.of<CategoryModel>(context, listen: false);

  TagModel get tagModel => Provider.of<TagModel>(context);

  ProductModel get productModel =>
      Provider.of<ProductModel>(context, listen: false);

  FilterAttributeModel get filterAttrModel =>
      Provider.of<FilterAttributeModel>(context, listen: false);

  UserModel get userModel => Provider.of<UserModel>(context, listen: false);

  AppModel get appModel => Provider.of<AppModel>(context, listen: false);

  /// Image ratio from Product Cart
  double get ratioProductImage => appModel.ratioProductImage;

  /// product list layout Filter
  String get layout => appModel.productListLayout;

  String? newTagId;
  String? newCategoryId;
  String? newListingLocationId;
  double? minPrice;
  double? maxPrice;
  String? orderBy;
  String? orDer;
  String? attribute;
  String? search;

//  int attributeTerm;
  bool? featured;
  bool? onSale;

  bool isFiltering = false;
  List<Product>? products = [];
  String? errMsg;
  int _page = 1;

  String _currentTitle = '';
  String _currentOrder = 'date';
  List? include;

  @override
  void initState() {
    super.initState();
    newCategoryId = productConfig.category ?? '-1';
    newTagId = productConfig.tag;
    onSale = productConfig.onSale;
    featured = productConfig.featured;
    orderBy = productConfig.orderby;
    newListingLocationId = widget.listingLocation;
    _currentOrder = (onSale ?? false) ? 'on_sale' : 'date';
    include = productConfig.include;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: 1.0,
    );

    /// only request to server if there is empty config params
    /// If there is config, load the products one
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      onRefresh(false);
    });
  }

  void onFilter({
    dynamic minPrice,
    dynamic maxPrice,
    dynamic categoryId,
    String? categoryName,
    String? tagId,
    dynamic attribute,
    dynamic currentSelectedTerms,
    dynamic listingLocationId,
    String? search,
  }) {
    printLog('[onFilter] ♻️ Reload product list');
    _controller.forward();

    if (listingLocationId != null) {
      newListingLocationId = listingLocationId;
    }

    if (minPrice == maxPrice && minPrice == 0) {
      this.minPrice = null;
      this.maxPrice = null;
    } else {
      this.minPrice = minPrice ?? this.minPrice;
      this.maxPrice = maxPrice ?? this.maxPrice;
    }

    if (tagId != null) {
      newTagId = tagId;
    }

    if (search != null) {
      this.search = search;
    }

    // set attribute
    if (attribute != null && !attribute.isEmpty) {
      this.attribute = attribute;
    }

    /// Set category title, ID
    if (categoryId != null) {
      newCategoryId = categoryId;

      final selectedCat = categoryModel.categories!
          .singleWhere((element) => element.id == categoryId.toString());
      productModel.categoryName = selectedCat.name;
      _currentTitle = selectedCat.name!;
    }

    /// reset paging and clean up product
    _page = 1;
    productModel.setProductsList([]);

    _getProductList();
    setState(() {});
  }

  void _getProductList() {
    productModel.getProductsList(
      categoryId: newCategoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      page: _page,
      lang: appModel.langCode,
      orderBy: orderBy,
      order: orDer,
      featured: featured,
      onSale: onSale,
      tagId: newTagId,
      attribute: attribute,
      attributeTerm: getAttributeTerm(),
      userId: userModel.user?.id,
      listingLocation: newListingLocationId,
      include: include,
      search: search,
    );
  }

  void onSort(String order) {
    _currentOrder = order;
    switch (order) {
      case 'featured':
        featured = true;
        onSale = null;
        break;
      case 'on_sale':
        featured = null;
        onSale = true;
        break;
      case 'price':
        featured = null;
        onSale = null;
        orderBy = 'price';
        break;
      case 'date':
      default:
        featured = null;
        onSale = null;
        orderBy = 'date';
        break;
    }

    _getProductList();
  }

  Future<void> onRefresh([loadingConfig = true]) async {
    setState(() {
      _page = 1;
    });
    _getProductList();
  }

  Widget? renderCategoryMenu({bool imageLayout = false}) {
    var parentCategoryId = newCategoryId;
    if (categoryModel.categories != null &&
        categoryModel.categories!.isNotEmpty) {
      parentCategoryId =
          getParentCategories(categoryModel.categories, parentCategoryId) ??
              parentCategoryId;

      var parentImage =
          categoryModel.categoryList[parentCategoryId.toString()]?.image ?? '';
      final listSubCategory =
          getSubCategories(categoryModel.categories, parentCategoryId)!;

      if (listSubCategory.length < 2) return null;

      return ListenableProvider.value(
        value: categoryModel,
        child: Consumer<CategoryModel>(builder: (context, value, child) {
          final listSubCategory =
              getSubCategories(categoryModel.categories, parentCategoryId)!;

          if (value.isLoading) {
            return Center(child: kLoadingWidget(context));
          }

          if (value.categories != null) {
            var _renderListCategory = <Widget>[];
            var _categoryMenu = kAdvanceConfig['categoryImageMenu'] ?? true;

            _renderListCategory.add(
              _renderItemCategory(
                context,
                categoryId: parentCategoryId,
                categoryName: S.of(context).seeAll,
                categoryImage:
                    _categoryMenu && parentImage.isNotEmpty && imageLayout
                        ? parentImage
                        : null,
              ),
            );

            _renderListCategory.addAll([
              for (var category in listSubCategory)
                _renderItemCategory(
                  context,
                  categoryId: category.id,
                  categoryName: category.name!,
                  categoryImage:
                      _categoryMenu && imageLayout ? category.image : null,
                )
            ]);

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              color: Color(0xFFcc0000),
              constraints: const BoxConstraints(minHeight: 50),
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _renderListCategory,
                  ),
                ),
              ),
            );
          }

          return Container();
        }),
      );
    }
    return null;
  }

  List<Category>? getSubCategories(categories, id) {
    return categories.where((o) => o.parent == id).toList();
  }

  String? getParentCategories(categories, id) {
    for (var item in categories) {
      if (item.id == id) {
        return (item.parent == null || item.parent == '0') ? null : item.parent;
      }
    }
    return '0';
  }

  Widget _renderItemCategory(
    BuildContext context, {
    String? categoryId,
    required String categoryName,
    String? categoryImage,
  }) {
    var highlightColor = newCategoryId == categoryId
        ? Theme.of(context).colorScheme.secondary.withOpacity(0.2)
        : Colors.transparent;
    return GestureDetector(
      onTap: () {
        include = null;
        onFilter(categoryId: categoryId);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: categoryImage != null ? 5 : 10,
          vertical: 4,
        ),
        margin: const EdgeInsets.only(left: 5, top: 10, bottom: 4),
        
        decoration: BoxDecoration(
          color: highlightColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
                child: Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontFamily: 'NeoRegular',
                    fontWeight: FontWeight.w700)
                ),
              ),
      ),
    );
  }

  String getAttributeTerm({bool showName = false}) {
    var terms = '';
    for (var i = 0; i < filterAttrModel.lstCurrentSelectedTerms.length; i++) {
      if (filterAttrModel.lstCurrentSelectedTerms[i]) {
        if (showName) {
          terms += '${filterAttrModel.lstCurrentAttr[i].name},';
        } else {
          terms += '${filterAttrModel.lstCurrentAttr[i].id},';
        }
      }
    }
    return terms.isNotEmpty ? terms.substring(0, terms.length - 1) : '';
  }

  void onLoadMore() {
    _page = _page + 1;
    _getProductList();
  }

  ProductBackdrop backdrop({products, isFetching, errMsg, isEnd, width}) {
    final isListView = layout != 'horizontal';
    return ProductBackdrop(
      backdrop: Backdrop(
        bgColor: productConfig.backgroundColor,
        selectSort: _currentOrder,
        frontLayer: isListView
            ? ProductList(
                products: products,
                onRefresh: onRefresh,
                onLoadMore: onLoadMore,
                isFetching: isFetching,
                errMsg: errMsg,
                isEnd: isEnd,
                layout: layout,
                ratioProductImage: ratioProductImage,
                width: width,
              )
            : AsymmetricView(
                products: products,
                isFetching: isFetching,
                isEnd: isEnd,
                onLoadMore: onLoadMore,
                width: width),
        backLayer: BackdropMenu(
          onFilter: onFilter,
          categoryId: newCategoryId,
          tagId: newTagId,
          listingLocationId: newListingLocationId,
        ),
        frontTitle: productConfig.showCountDown
            ? Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_currentTitle),
                      CountDownTimer(widget.countdownDuration)
                    ],
                  ),
                ],
              )
            : Text(_currentTitle, style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontFamily: 'NeoRegular',
                    fontWeight: FontWeight.w700),
                    ),
        backTitle: Text(S.of(context).filter, style:const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontFamily: 'NeoRegular',
                    fontWeight: FontWeight.w700),),
        controller: _controller,
        onSort: onSort,
        appbarCategory: renderCategoryMenu(),
      ),
      expandingBottomSheet: (kEnableShoppingCart && !Config().isListingType)
          ? ExpandingBottomSheet(hideController: _controller)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    _currentTitle = productConfig.name ??
        productModel.categoryName ??
        S.of(context).products;

    Widget buildMain = LayoutBuilder(
      builder: (context, constraint) {
        return FractionallySizedBox(
          widthFactor: 1.0,
          child: ListenableProvider.value(
            value: productModel,
            child: Consumer<ProductModel>(
              builder: (context, value, child) {
                var backdropLayout =
                    kAdvanceConfig['enableProductBackdrop'] ?? false;

                if (!backdropLayout) {
                  var tagName = tagModel.tags?[newTagId.toString()]?.name ?? '';
                  var _currentCategory =
                      categoryModel.categoryList[productModel.categoryId];
                  var _attributeTerms = getAttributeTerm(showName: true);
                  var _attributeList = _attributeTerms.isNotEmpty
                      ? _attributeTerms.split(',')
                      : [];

                  return ProductFlatView(
                    builder: (controller) => ProductList(
                      scrollController: controller,
                      products: value.productsList,
                      onRefresh: onRefresh,
                      onLoadMore: onLoadMore,
                      isFetching: value.isFetching,
                      errMsg: value.errMsg,
                      isEnd: value.isEnd,
                      layout: layout,
                      ratioProductImage: ratioProductImage,
                      width: constraint.maxWidth,
                      header: [
                        const SizedBox(height: 44),
                        renderCategoryMenu(imageLayout: true) ??
                            const SizedBox(),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 10, right: 10, bottom: 10, top: 25),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _currentTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline5!
                                        .copyWith(
                                          fontWeight: FontWeight.w700,
                                          height: 0.6,
                                        ),
                                  ),
                                  const Spacer(),
                                  if (_currentCategory != null) ...[
                                    Text(
                                      _currentCategory.totalProduct.toString() +
                                          ' ' +
                                          S.of(context).items,
                                      style: Theme.of(context)
                                          .textTheme
                                          .caption!
                                          .copyWith(
                                            color: Theme.of(context).hintColor,
                                          ),
                                    ),
                                    const SizedBox(width: 5),
                                  ]
                                ],
                              ),
                              if (productConfig.showCountDown) ...[
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Text(
                                      S.of(context).endsIn('').toUpperCase(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary
                                                .withOpacity(0.8),
                                          )
                                          .apply(fontSizeFactor: 0.6),
                                    ),
                                    CountDownTimer(widget.countdownDuration),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        )
                      ],
                    ),
                    titleFilter: Row(
                      children: [
                        if (_attributeList.isNotEmpty)
                          for (int i = 0; i < _attributeList.length; i++)
                            FilterLabel(
                              label: _attributeList[i].toString(),
                              onTap: () {
                                filterAttrModel.resetFilter();
                                onFilter();
                              },
                            ),
                        if (tagName.isNotEmpty)
                          FilterLabel(
                            label: tagName.capitalize(),
                            onTap: () {
                              productModel.resetTag();
                              onFilter(tagId: '');
                            },
                          ),
                        if (minPrice != null &&
                            maxPrice != null &&
                            maxPrice != 0)
                          FilterLabel(
                            onTap: () {
                              productModel.resetPrice();
                              onFilter(minPrice: 0.0, maxPrice: 0.0);
                            },
                            label: (minPrice?.toStringAsFixed(0) ?? '') +
                                ' - ' +
                                (maxPrice?.toStringAsFixed(0) ?? ''),
                          ),
                      ],
                    ),
                    onSort: onSort,
                    onFilter: onFilter,
                    onSearch: (String searchText) => {
                      onFilter(
                        minPrice: minPrice,
                        maxPrice: maxPrice,
                        categoryId: newCategoryId,
                        tagId: newTagId,
                        listingLocationId: newListingLocationId,
                        search: searchText,
                      )
                    },
                    filterMenu: (scrollController) => BackdropMenu(
                      onFilter: onFilter,
                      categoryId: newCategoryId,
                      tagId: newTagId,
                      listingLocationId: newListingLocationId,
                      controller: scrollController,
                      minPrice: minPrice,
                      maxPrice: maxPrice,
                    ),
                    bottomSheet:
                        (kEnableShoppingCart && !Config().isListingType)
                            ? ExpandingBottomSheet(hideController: _controller)
                            : null,
                  );
                }
                return backdrop(
                    products: value.productsList,
                    isFetching: value.isFetching,
                    errMsg: value.errMsg,
                    isEnd: value.isEnd,
                    width: constraint.maxWidth);
              },
            ),
          ),
        );
      },
    );

    return kIsWeb
        ? WillPopScope(
            onWillPop: () async {
              eventBus.fire(const EventOpenCustomDrawer());
              // LayoutWebCustom.changeStateMenu(true);
              Navigator.of(context).pop();
              return false;
            },
            child: buildMain,
          )
        : buildMain;
  }
}
