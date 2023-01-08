import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common/config.dart';
import '../common/config/models/index.dart';
import '../common/constants.dart';
import '../common/tools.dart';
import '../generated/l10n.dart';
import '../models/index.dart'
    show AppModel, BackDropArguments, Category, CategoryModel, UserModel;
import '../modules/dynamic_layout/config/app_config.dart';
import '../modules/dynamic_layout/helper/helper.dart';
import '../routes/flux_navigate.dart';
import '../services/index.dart';
import '../widgets/common/index.dart' show FluxImage, WebView;
import '../widgets/general/index.dart';
import 'maintab_delegate.dart';

class SideBarMenu extends StatefulWidget {
  const SideBarMenu();

  @override
  MenuBarState createState() => MenuBarState();
}

class MenuBarState extends State<SideBarMenu> {
  bool get isEcommercePlatform =>
      !Config().isListingType || !Config().isWordPress;

  DrawerMenuConfig get drawer =>
      Provider.of<AppModel>(context, listen: false).appConfig?.drawer ??
      kDefaultDrawer;

  void pushNavigation(String name) {
    eventBus.fire(const EventCloseNativeDrawer());
    MainTabControlDelegate.getInstance().changeTab(name.replaceFirst('/', ''));
  }

  @override
  Widget build(BuildContext context) {
    printLog('[AppState] Load Menu');

    return Padding(
      key: drawer.key != null ? Key(drawer.key as String) : UniqueKey(),
      padding: EdgeInsets.only(
          bottom: injector<AudioManager>().isStickyAudioWidgetActive ? 46 : 0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (drawer.logo != null) ...[
              Container(
                color: drawer.logoConfig.backgroundColor != null
                    ? HexColor(drawer.logoConfig.backgroundColor)
                    : null,
                padding: EdgeInsets.only(
                  bottom: drawer.logoConfig.marginBottom.toDouble(),
                  top: drawer.logoConfig.marginTop.toDouble(),
                  left: drawer.logoConfig.marginLeft.toDouble(),
                  right: drawer.logoConfig.marginRight.toDouble(),
                ),
                child: Image.asset('assets/images/logotipo.png', width: 150,),
              ),
              const Divider(),
            ],
            ...List.generate(
              drawer.items?.length ?? 0,
              (index) {
                return drawerItem(
                  drawer.items![index],
                  drawer.subDrawerItem ?? {},
                  textColor: drawer.textColor != null
                      ? HexColor(drawer.textColor)
                      : null,
                  iconColor: drawer.iconColor != null
                      ? HexColor(drawer.iconColor)
                      : null,
                );
              },
            ),
            isDisplayDesktop(context)
                ? const SizedBox(height: 300)
                : const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget drawerItem(
    DrawerItemsConfig drawerItemConfig,
    Map<String, GeneralSettingItem> subDrawerItem, {
    Color? iconColor,
    Color? textColor,
  }) {
    // final isTablet = Tools.isTablet(MediaQuery.of(context));

    if (drawerItemConfig.show == false) return const SizedBox();
    var value = drawerItemConfig.type;
    var textStyle = TextStyle(
      color: textColor ?? Theme.of(context).textTheme.bodyText1?.color,
    );

    switch (value) {
      case 'home':
        {
          return ListTile(
            leading: Icon(
              isEcommercePlatform ? Icons.home : Icons.shopping_basket,
              size: 20,
              color: const Color(0xFFcc0000),
            ),
            title: const Text('Inicio',
              style:  TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: 'NeoRegular',),
            ),
            onTap: () {
              pushNavigation(RouteList.home);
            },
          );
        }
      case 'categories':
        {
          return ListTile(
            leading: Icon(
              Icons.category,
              size: 20,
              color: iconColor,
            ),
            title: Text(
              S.of(context).categories,
              style: textStyle,
            ),
            onTap: () => pushNavigation(
              Provider.of<AppModel>(context, listen: false).vendorType ==
                      VendorType.single
                  ? RouteList.category
                  : RouteList.vendorCategory,
            ),
          );
        }
      case 'cart':
        {
          if (Config().isListingType) {
            return Container();
          }
          return ListTile(
            leading: Icon(
              Icons.shopping_cart,
              size: 20,
              color: iconColor,
            ),
            title: Text(
              S.of(context).cart,
              style: textStyle,
            ),
            onTap: () => pushNavigation(RouteList.cart),
          );
        }
      case 'profile':
        {
          return ListTile(
            leading: Icon(
              Icons.person,
              size: 20,
              color: iconColor,
            ),
            title: Text(
              S.of(context).settings,
              style: textStyle,
            ),
            onTap: () => pushNavigation(RouteList.profile),
          );
        }
      case 'web':
        {
          return ListTile(
            leading: Icon(
              Icons.web,
              size: 20,
              color: iconColor,
            ),
            title: Text(
              S.of(context).webView,
              style: textStyle,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WebView(
                    url: 'https://inspireui.com',
                    title: S.of(context).webView,
                  ),
                ),
              );
            },
          );
        }
    
      case 'login':
        {
          return ListenableProvider.value(
            value: Provider.of<UserModel>(context, listen: false),
            child: Consumer<UserModel>(builder: (context, userModel, _) {
              final loggedIn = userModel.loggedIn;
              return ListTile(
                leading: Icon(Icons.exit_to_app, size: 20, color: Color(0xFFcc0000)),
                title: loggedIn
                    ? Text(S.of(context).logout, style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: 'NeoRegular',))
                    : Text(S.of(context).login, style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: 'NeoRegular',)),
                onTap: () {
                  if (loggedIn) {
                    Provider.of<UserModel>(context, listen: false).logout();
                    if (kLoginSetting['IsRequiredLogin'] ?? false) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        RouteList.login,
                        (route) => false,
                      );
                    }
                    // else {
                    //   pushNavigation(RouteList.dashboard);
                    // }
                  } else {
                    pushNavigation(RouteList.login);
                  }
                },
              );
            }),
          );
        }
      case 'category':
        {
          return buildListCategory(textStyle: textStyle);
        }
      default:
        {
          var item = subDrawerItem[value];
          if (value?.contains('web') ?? false) {
            return GeneralWebWidget(
              item: item,
              useTile: true,
              iconColor: iconColor,
              textStyle: textStyle,
            );
          }
          if (value?.contains('post') ?? false) {
            return GeneralPostWidget(
              item: item,
              useTile: true,
              iconColor: iconColor,
              textStyle: textStyle,
            );
          }
          if (value?.contains('title') ?? false) {
            return GeneralTitleWidget(item: item);
          }
          if (value?.contains('button') ?? false) {
            return GeneralButtonWidget(item: item);
          }
        }

        return const SizedBox();
    }
  }

  Widget buildListCategory({TextStyle? textStyle}) {
    final categories = Provider.of<CategoryModel>(context).categories;
    var widgets = <Widget>[];

    if (categories != null) {
      var list = categories.where((item) => item.parent == '0').toList();
      for (var i = 0; i < list.length; i++) {
        final currentCategory = list[i];
        var childCategories =
            categories.where((o) => o.parent == currentCategory.id).toList();
        widgets.add(Container(
          color: i.isOdd
              ? null
              : Theme.of(context).colorScheme.secondary.withOpacity(0.1),

          /// Check to add only parent link category
          child: childCategories.isEmpty
              ? InkWell(
                  onTap: () => navigateToBackDrop(currentCategory),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: 20,
                      bottom: 12,
                      left: 16,
                      top: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Text(
                          currentCategory.name!,
                          style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: 'NeoRegular',),
                        )),
                        const SizedBox(width: 24),
                        currentCategory.totalProduct == null
                            ? const Icon(Icons.chevron_right)
                            : Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  S
                                      .of(context)
                                      .nItems(currentCategory.totalProduct!),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFcc0000),
                                    fontFamily: 'NeoRegular',)
                                ),
                              ),
                      ],
                    ),
                  ),
                )
              : ExpansionTile(
                  title: Padding(
                    padding: const EdgeInsets.only(left: 0.0, top: 0),
                    child: Text(
                      currentCategory.name!,
                      style:const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: 'NeoRegular',)
                    ),
                  ),
                  textColor: Theme.of(context).primaryColor,
                  iconColor: Theme.of(context).primaryColor,
                  children:
                      getChildren(categories, currentCategory, childCategories)
                          as List<Widget>,
                ),
        ));
      }
    }

    return ExpansionTile(
      initiallyExpanded: true,
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      tilePadding: const EdgeInsets.only(left: 16, right: 8),
      title: Text(
        S.of(context).byCategory.toUpperCase(),
        style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontFamily: 'NeoRegular',
                    fontWeight: FontWeight.w700)
      ),
      children: widgets,
    );
  }

  List getChildren(
    List<Category> categories,
    Category currentCategory,
    List<Category> childCategories, {
    double paddingOffset = 0.0,
  }) {
    var list = <Widget>[];
    final totalProduct = currentCategory.totalProduct;
    list.add(
      ListTile(
        leading: Padding(
          padding: EdgeInsets.only(left: 20 + paddingOffset),
          child: Text(S.of(context).seeAll),
        ),
        trailing: ((totalProduct != null && totalProduct > 0))
            ? Text(
                S.of(context).nItems(totalProduct),
                style: const TextStyle(
                             fontSize: 12,
                              color: Color(0xFFcc0000),
                              fontFamily: 'NeoRegular',)
              )
            : null,
        onTap: () => navigateToBackDrop(currentCategory),
      ),
    );
    for (var i in childCategories) {
      var newChildren = categories.where((cat) => cat.parent == i.id).toList();
      if (newChildren.isNotEmpty) {
        list.add(
          ExpansionTile(
            title: Padding(
              padding: EdgeInsets.only(left: 20.0 + paddingOffset),
              child: Text(
                i.name!.toUpperCase(),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            children: getChildren(
              categories,
              i,
              newChildren,
              paddingOffset: paddingOffset + 10,
            ) as List<Widget>,
          ),
        );
      } else {
        final totalProduct = i.totalProduct;
        list.add(
          ListTile(
            title: Padding(
              padding: EdgeInsets.only(left: 20 + paddingOffset),
              child: Text(i.name!),
            ),
            trailing: (totalProduct != null && totalProduct > 0)
                ? Text(
                    S.of(context).nItems(i.totalProduct!),
                    style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontFamily: 'NeoRegular',)
                  )
                : null,
            onTap: () => navigateToBackDrop(i),
          ),
        );
      }
    }
    return list;
  }

  void navigateToBackDrop(Category category) {
    FluxNavigate.pushNamed(
      RouteList.backdrop,
      arguments: BackDropArguments(
        cateId: category.id,
        cateName: category.name,
      ),
    );
  }
}
