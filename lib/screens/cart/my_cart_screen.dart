import 'package:flash/flash.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inspireui/inspireui.dart' show AutoHideKeyboard, printLog;
import 'package:provider/provider.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../generated/l10n.dart';
import '../../menu/index.dart' show MainTabControlDelegate;
import '../../models/index.dart' show AppModel, CartModel, Product, UserModel;
import '../../routes/flux_navigate.dart';
import '../../services/index.dart';
import '../../widgets/product/cart_item.dart';
import '../../widgets/product/product_bottom_sheet.dart';
import '../checkout/checkout_screen.dart';
import 'widgets/empty_cart.dart';
import 'widgets/shopping_cart_sumary.dart';
import 'widgets/wishlist.dart';

class MyCart extends StatefulWidget {
  final bool? isModal;
  final bool? isBuyNow;

  const MyCart({
    this.isModal,
    this.isBuyNow = false,
  });

  @override
  _MyCartState createState() => _MyCartState();
}

class _MyCartState extends State<MyCart> with SingleTickerProviderStateMixin {
  bool isLoading = false;
  String errMsg = '';

  CartModel get cartModel => Provider.of<CartModel>(context, listen: false);

  List<Widget> _createShoppingCartRows(CartModel model, BuildContext context) {
    return model.productsInCart.keys.map(
      (key) {
        var productId = Product.cleanProductID(key);
        var product = model.getProductById(productId);

        if (product != null) {
          return ShoppingCartRow(
            product: product,
            addonsOptions: model.productAddonsOptionsInCart[key],
            variation: model.getProductVariationById(key),
            quantity: model.productsInCart[key],
            options: model.productsMetaDataInCart[key],
            onRemove: () {
              model.removeItemFromCart(key);
            },
            onChangeQuantity: (val) {
              var message =
                  model.updateQuantity(product, key, val, context: context);
              if (message.isNotEmpty) {
                final snackBar = SnackBar(
                  content: Text(message),
                  duration: const Duration(seconds: 1),
                );
                Future.delayed(
                  const Duration(milliseconds: 300),
                  // ignore: deprecated_member_use
                  () => Scaffold.of(context).showSnackBar(snackBar),
                );
              }
            },
          );
        }
        return const SizedBox();
      },
    ).toList();
  }

  void _loginWithResult(BuildContext context) async {
    // final result = await Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => LoginScreen(
    //       fromCart: true,
    //     ),
    //     fullscreenDialog: kIsWeb,
    //   ),
    // );
    await FluxNavigate.pushNamed(
      RouteList.login,
      forceRootNavigator: true,
    ).then((value) {
      final user = Provider.of<UserModel>(context, listen: false).user;
      if (user != null && user.name != null) {
        Tools.showSnackBar(
            Scaffold.of(context), S.of(context).welcome + ' ${user.name} !');
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    printLog('[Cart] build');

    final localTheme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    var layoutType = Provider.of<AppModel>(context).productDetailLayout;
    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    final canPop = parentRoute?.canPop ?? false;

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      floatingActionButton: Selector<CartModel, bool>(
        selector: (_, cartModel) => cartModel.calculatingDiscount,
        builder: (context, calculatingDiscount, child) {
          return FloatingActionButton.extended(
            onPressed: calculatingDiscount
                ? null
                : () {
                    if (kAdvanceConfig['AlwaysShowTabBar'] ?? false) {
                      MainTabControlDelegate.getInstance().changeTab('cart');
                      // return;
                    }
                    onCheckout(cartModel);
                  },
            elevation: 0,
            isExtended: true,
            extendedTextStyle: const TextStyle(
              letterSpacing: 0.8,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            extendedPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9.0),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            label: child!,
          );
        },
        child: Selector<CartModel, int>(
          selector: (_, carModel) => cartModel.totalCartQuantity,
          builder: (context, totalCartQuantity, child) {
            // if (totalCartQuantity == 0) {
            //   return const SizedBox();
            // }
            return Center(
              child: Container(
                width: screenSize.width -48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    totalCartQuantity > 0
                        ? (isLoading
                            ? Text(S.of(context).loading, 
                        style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'NeoRegular',
                        fontWeight: FontWeight.w700),)
                        : Text(S.of(context).checkout, 
                        style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'NeoRegular',
                        fontWeight: FontWeight.w700),))
                        : Text(S.of(context).startShopping, 
                        style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'NeoRegular',
                        fontWeight: FontWeight.w700),
                        ),
                    const SizedBox(width: 3),
                    const Icon(CupertinoIcons.right_chevron, size: 12),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Container(
       color: const Color(0xFFcc0000),
        child: SafeArea(
          child: Container(
            color: Colors.white,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  
                  pinned: true,
                  centerTitle: false,
                  leading: widget.isModal == true
                      ? CloseButton(
                          onPressed: () {
                            if (widget.isBuyNow!) {
                              Navigator.of(context).pop();
                              return;
                            }

                            if (Navigator.of(context).canPop() &&
                                layoutType != 'simpleType') {
                              Navigator.of(context).pop();
                            } else {
                              ExpandingBottomSheet.of(context, isNullOk: true)
                                  ?.close();
                            }
                          },
                        )
                      : canPop
                          ? const BackButton()
                          : null,
                  backgroundColor: const Color(0xFFcc0000),
                  title: const Text(
                    'Carrito',
                    style:  TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontFamily: 'NeoRegular',
                          fontWeight: FontWeight.w700),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Consumer<CartModel>(
                    builder: (context, model, child) {
                      return AutoHideKeyboard(
                        child: Container(
                          decoration:
                              BoxDecoration(color: Theme.of(context).backgroundColor),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 80.0),
                              child: Column(
                                children: [
                                  if (model.totalCartQuantity > 0)
                                    Container(
                                      // decoration: BoxDecoration(
                                      //     color: Theme.of(context).primaryColorLight),
                                      padding: const EdgeInsets.only(
                                        right: 15.0,
                                        top: 4.0,
                                      ),
                                      child: SizedBox(
                                        width: screenSize.width,
                                        child: SizedBox(
                                          width: screenSize.width /
                                              (2 /
                                                  (screenSize.height /
                                                      screenSize.width)),
                                          child: Row(
                                            children: [
                                              const SizedBox(width: 25.0),
                                              Container(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Text(
                                                  S.of(context).total.toUpperCase(),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFFcc0000),
                                                    fontFamily: 'NeoRegular',
                                                    fontWeight: FontWeight.w700)
                                                ),
                                              ),
                                              const SizedBox(width: 8.0),
                                              Text(
                                                '${model.totalCartQuantity} ${S.of(context).items}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Color(0xFFcc0000),
                                                  fontFamily: 'NeoRegular',
                                                  fontWeight: FontWeight.w700),
                                              ),
                                              Expanded(
                                                child: Align(
                                                  alignment: Tools.isRTL(context)
                                                      ? Alignment.centerLeft
                                                      : Alignment.centerRight,
                                                  child: TextButton(
                                                    onPressed: () {
                                                      if (model.totalCartQuantity >
                                                          0) {
                                                        showDialog(
                                                          context: context,
                                                          useRootNavigator: false,
                                                          builder:
                                                              (BuildContext context) {
                                                            return AlertDialog(
                                                              content: Text(S
                                                                  .of(context)
                                                                  .confirmClearTheCart),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                  },
                                                                  child: Text(S
                                                                      .of(context)
                                                                      .keep),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed: () {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                    model.clearCart();
                                                                  },
                                                                  child: Text(
                                                                    S
                                                                        .of(context)
                                                                        .clear,
                                                                    style:
                                                                        const TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      }
                                                    },
                                                    child: Text(
                                                      S
                                                          .of(context)
                                                          .clearCart
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFcc0000),
                      fontFamily: 'NeoRegular',)
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (model.totalCartQuantity > 0)
                                    const Divider(
                                      height: 1,
                                      // indent: 25,
                                    ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      const SizedBox(height: 16.0),
                                      if (model.totalCartQuantity > 0)
                                        Column(
                                          children:
                                              _createShoppingCartRows(model, context),
                                        ),
                                      const ShoppingCartSummary(),
                                      if (model.totalCartQuantity == 0) EmptyCart(),
                                      if (errMsg.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 15,
                                            vertical: 10,
                                          ),
                                          child: Text(
                                            errMsg,
                                            style: const TextStyle(color: Colors.red),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      const SizedBox(height: 4.0),
                                      WishList()
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onCheckout(CartModel model) {
    var isLoggedIn = Provider.of<UserModel>(context, listen: false).loggedIn;
    final currencyRate =
        Provider.of<AppModel>(context, listen: false).currencyRate;
    final currency = Provider.of<AppModel>(context, listen: false).currency;
    var message;

    if (isLoading) return;

    if (kCartDetail['minAllowTotalCartValue'] != null) {
      if (kCartDetail['minAllowTotalCartValue'].toString().isNotEmpty) {
        var totalValue = model.getSubTotal() ?? 0;
        var minValue = PriceTools.getCurrencyFormatted(
            kCartDetail['minAllowTotalCartValue'], currencyRate,
            currency: currency);
        if (totalValue < kCartDetail['minAllowTotalCartValue'] &&
            model.totalCartQuantity > 0) {
          message = '${S.of(context).totalCartValue} $minValue';
        }
      }
    }

    if ((kVendorConfig['DisableMultiVendorCheckout'] ?? false) &&
        Config().isVendorType()) {
      if (!model.isDisableMultiVendorCheckoutValid(
          model.productsInCart, model.getProductById)) {
        message = S.of(context).youCanOnlyOrderSingleStore;
      }
    }

    if (message != null) {
      showFlash(
        context: context,
        duration: const Duration(seconds: 3),
        persistent: !Config().isBuilder,
        builder: (context, controller) {
          return SafeArea(
            child: Flash(
              borderRadius: BorderRadius.circular(3.0),
              backgroundColor: Theme.of(context).errorColor,
              controller: controller,
              behavior: FlashBehavior.fixed,
              position: FlashPosition.top,
              horizontalDismissDirection: HorizontalDismissDirection.horizontal,
              child: FlashBar(
                icon: const Icon(
                  Icons.check,
                  color: Colors.white,
                ),
                content: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      );

      return;
    }

    if (model.totalCartQuantity == 0) {
      if (widget.isModal == true) {
        try {
          ExpandingBottomSheet.of(context)!.close();
        } catch (e) {
          Navigator.of(context).pushNamed(RouteList.dashboard);
        }
      } else {
        final modalRoute = ModalRoute.of(context);
        if (modalRoute?.canPop ?? false) {
          Navigator.of(context).pop();
          return;
        }
        MainTabControlDelegate.getInstance().tabAnimateTo(0);
      }
    } else if (isLoggedIn || kPaymentConfig['GuestCheckout'] == true) {
      doCheckout();
    } else {
      _loginWithResult(context);
    }
  }

  Future<void> doCheckout() async {
    showLoading();

    await Services().widget.doCheckout(
      context,
      success: () async {
        hideLoading('');
        await FluxNavigate.pushNamed(
          RouteList.checkout,
          arguments: CheckoutArgument(isModal: widget.isModal),
          forceRootNavigator: true,
        );
      },
      error: (message) async {
        if (message ==
            Exception('Token expired. Please logout then login again')
                .toString()) {
          setState(() {
            isLoading = false;
          });
          //logout
          final userModel = Provider.of<UserModel>(context, listen: false);
          await userModel.logout();
          Services().firebase.signOut();

          _loginWithResult(context);
        } else {
          hideLoading(message);
          Future.delayed(const Duration(seconds: 3), () {
            setState(() => errMsg = '');
          });
        }
      },
      loading: (isLoading) {
        setState(() {
          this.isLoading = isLoading;
        });
      },
    );
  }

  void showLoading() {
    setState(() {
      isLoading = true;
      errMsg = '';
    });
  }

  void hideLoading(error) {
    setState(() {
      isLoading = false;
      errMsg = error;
    });
  }
}
