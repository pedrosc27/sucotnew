// Copyright 2018-present the Flutter authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the 'License');
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../common/tools/adaptive_tools.dart';
import '../../generated/l10n.dart';
import '../../models/index.dart';
import '../../modules/firebase/dynamic_link_service.dart';
import '../../services/service_config.dart';
import '../../services/services.dart';
import 'backdrop_constants.dart';

const Cubic _kAccelerateCurve = Cubic(0.548, 0.0, 0.757, 0.464);
const Cubic _kDecelerateCurve = Cubic(0.23, 0.94, 0.41, 1.0);
const double _kPeakVelocityTime = 0.248210;
const double _kPeakVelocityProgress = 0.379146;

class _FrontLayer extends StatelessWidget {
  const _FrontLayer({Key? key, this.onTap, this.child, this.visible})
      : super(key: key);

  final VoidCallback? onTap;
  final Widget? child;
  final bool? visible;

  @override
  Widget build(BuildContext context) {
    var radius = visible! ? 12.0 : 16.0;

    return Material(
      elevation: 16.0,
      color: Colors.white,
 
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Container(
                
                height: visible! ? 10.0 : 40.0,
                alignment: AlignmentDirectional.centerStart,
              ),
            ),
            Expanded(
              child: child!,
            ),
          ],
        ),
      ),
    );
  }
}

class _BackdropTitle extends AnimatedWidget {
  final Function? onPress;
  final Widget frontTitle;
  final Widget backTitle;
  final bool? visible;
  final Color? titleColor;

  const _BackdropTitle({
    Key? key,
    required Listenable listenable,
    this.onPress,
    this.visible,
    this.titleColor,
    required this.frontTitle,
    required this.backTitle,
  }) : super(key: key, listenable: listenable);

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = CurvedAnimation(
      parent: listenable as Animation<double>,
      curve: const Interval(0.0, 0.78),
    );

    return DefaultTextStyle(
      style: Theme.of(context)
          .textTheme
          .headline6!
          .copyWith(color: titleColor ?? Colors.white),
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      child: Stack(
        children: <Widget>[
          Opacity(
            opacity: CurvedAnimation(
              parent: ReverseAnimation(animation),
              curve: const Interval(0.5, 1.0),
            ).value,
            child: FractionalTranslation(
              translation: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(0.5, 0.0),
              ).evaluate(animation),
              child: backTitle,
            ),
          ),
          Opacity(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0.5, 1.0),
            ).value,
            child: FractionalTranslation(
              translation: Tween<Offset>(
                begin: const Offset(-0.25, 0.0),
                end: Offset.zero,
              ).evaluate(animation),
              child: frontTitle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Builds a Backdrop.
///
/// A Backdrop widget has two layers, front and back. The front layer is shown
/// by default, and slides down to show the back layer, from which a user
/// can make a selection. The user can also configure the titles for when the
/// front or back layer is showing.
class Backdrop extends StatefulWidget {
  final Widget frontLayer;
  final Widget backLayer;
  final Widget frontTitle;
  final Widget backTitle;
  final Widget? appbarCategory;
  final AnimationController controller;
  final Function? onSort;
  final String selectSort;
  final bool showSort;
  final bool showFilter;

  /// This color is pick from the Horizontal Config on Home Screen
  /// use to override the Backdrop color
  final Color? bgColor;

  const Backdrop({
    required this.frontLayer,
    required this.backLayer,
    required this.frontTitle,
    required this.backTitle,
    required this.controller,
    this.appbarCategory,
    this.onSort,
    this.selectSort = 'date',
    this.showSort = true,
    this.showFilter = true,
    this.bgColor,
  });

  @override
  _BackdropState createState() => _BackdropState();
}

class _BackdropState extends State<Backdrop>
    with SingleTickerProviderStateMixin {
  final GlobalKey _backdropKey = GlobalKey(debugLabel: 'Backdrop');
  late AnimationController _controller;
  late Animation<RelativeRect> _layerAnimation;
  String _selectSort = 'date';

  /// background color
  bool get useBackgroundColor =>
      productFilterColor?.useBackgroundColor ?? false;
  bool get userPrimaryColorLight =>
      productFilterColor?.usePrimaryColorLight ?? false;

  Color get systemBackgroundColor => useBackgroundColor
      ? Theme.of(context).backgroundColor
      : (userPrimaryColorLight
          ? Theme.of(context).primaryColorLight
          : Theme.of(context).primaryColor);
  Color get backgroundColor =>
      widget.bgColor ??
      ((productFilterColor?.backgroundColor != null
              ? HexColor(productFilterColor?.backgroundColor)
              : systemBackgroundColor))
          .withOpacity(
              productFilterColor?.backgroundColorOpacity.toDouble() ?? 1.0);

  /// label color
  Color get systemLabelColor => (productFilterColor?.useAccentColor ?? false)
      ? Theme.of(context).colorScheme.secondary
      : Colors.white;

  Color get labelColor {
    /// use the label color from bgColor
    if (widget.bgColor != null) {
      return widget.bgColor!.computeLuminance() > 0.5
          ? Colors.black
          : Colors.white;
    }

    return (productFilterColor?.labelColor != null
            ? HexColor(productFilterColor?.labelColor)
            : systemLabelColor)
        .withOpacity(productFilterColor?.labelColorOpacity.toDouble() ?? 1.0);
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _selectSort = widget.selectSort;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _frontLayerVisible {
    final status = _controller.status;
    return status == AnimationStatus.completed ||
        status == AnimationStatus.forward;
  }

  bool shouldShowCategory = true;

  void _toggleBackdropLayerVisibility() {
    // Call setState here to update layerAnimation if that's necessary
    setState(() {
      _frontLayerVisible ? _controller.reverse() : _controller.forward();
    });
    // Future.delayed(Duration(milliseconds: _frontLayerVisible ? 0 : 75), () {
    //   setState(() {
    //     shouldShowCategory = _frontLayerVisible;
    //   });
    // });
  }

  // _layerAnimation animates the front layer between open and close.
  // _getLayerAnimation adjusts the values in the TweenSequence so the
  // curve and timing are correct in both directions.
  Animation<RelativeRect> _getLayerAnimation(Size layerSize, double layerTop) {
    Curve firstCurve; // Curve for first TweenSequenceItem
    Curve secondCurve; // Curve for second TweenSequenceItem
    double firstWeight; // Weight of first TweenSequenceItem
    double secondWeight; // Weight of second TweenSequenceItem
    Animation animation; // Animation on which TweenSequence runs

    if (_frontLayerVisible) {
      firstCurve = _kAccelerateCurve;
      secondCurve = _kDecelerateCurve;
      firstWeight = _kPeakVelocityTime;
      secondWeight = 1.0 - _kPeakVelocityTime;
      animation = CurvedAnimation(
        parent: _controller.view,
        curve: const Interval(0.0, 0.78),
      );
    } else {
      // These values are only used when the controller runs from t=1.0 to t=0.0
      firstCurve = _kDecelerateCurve.flipped;
      secondCurve = _kAccelerateCurve.flipped;
      firstWeight = 1.0 - _kPeakVelocityTime;
      secondWeight = _kPeakVelocityTime;
      animation = _controller.view;
    }

    return TweenSequence(
      <TweenSequenceItem<RelativeRect>>[
        TweenSequenceItem<RelativeRect>(
          tween: RelativeRectTween(
            begin: RelativeRect.fromLTRB(
              0.0,
              layerTop,
              0.0,
              layerTop - layerSize.height,
            ),
            end: RelativeRect.fromLTRB(
              0.0,
              layerTop * _kPeakVelocityProgress,
              0.0,
              (layerTop - layerSize.height) * _kPeakVelocityProgress,
            ),
          ).chain(CurveTween(curve: firstCurve)),
          weight: firstWeight,
        ),
        TweenSequenceItem<RelativeRect>(
          tween: RelativeRectTween(
            begin: RelativeRect.fromLTRB(
              0.0,
              layerTop * _kPeakVelocityProgress,
              0.0,
              (layerTop - layerSize.height) * _kPeakVelocityProgress,
            ),
            end: RelativeRect.fill,
          ).chain(CurveTween(curve: secondCurve)),
          weight: secondWeight,
        ),
      ],
    ).animate(animation as Animation<double>);
  }

  Widget _buildStack(BuildContext context, BoxConstraints constraints) {
    const layerTitleHeight = 20.0;
    final layerSize = constraints.biggest;
    final layerTop = layerSize.height - layerTitleHeight;
    _layerAnimation = _getLayerAnimation(layerSize, layerTop);

    return Stack(
      key: _backdropKey,
      fit: StackFit.expand,
      children: <Widget>[
        Container(
         
          child: Theme(
            data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      secondary: labelColor,
                    ),
                textTheme: Theme.of(context).textTheme.copyWith(
                      subtitle1:
                          Theme.of(context).textTheme.subtitle1?.copyWith(
                                color: labelColor,
                              ),
                      headline6:
                          Theme.of(context).textTheme.headline6?.copyWith(
                                color: labelColor,
                              ),
                    )),
            child: widget.backLayer,
          ),
        ),
        PositionedTransition(
          rect: _layerAnimation,
          child: _FrontLayer(
            onTap: _toggleBackdropLayerVisibility,
            visible: _frontLayerVisible,
            child: widget.frontLayer,
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
      IconData icon, String label, String value,
      [bool isSelect = false]) {
    final menuItemStyle = TextStyle(
      fontSize: 13.0,
      color: isSelect
          ? Theme.of(context).primaryColor
          : Theme.of(context).colorScheme.secondary,
      height: 24.0 / 15.0,
    );
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: Icon(icon,
                color: isSelect
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).colorScheme.secondary,
                size: 17),
          ),
          Text(label, style: menuItemStyle),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const _appBarCategoryHeight = 50.0;

    var appBar = AppBar(
      backgroundColor: Color(0xFFcc0000),
      elevation: 0.0,
      titleSpacing: 0.0,
      bottom: Config().isListingType
          ? null
          : widget.appbarCategory != null
              ? PreferredSize(
                  preferredSize: Size(
                    MediaQuery.of(context).size.width,
                    shouldShowCategory ? _appBarCategoryHeight : 0,
                  ),
                  child: SizedBox(
                    height: shouldShowCategory ? _appBarCategoryHeight : 0,
                    child: AnimatedOpacity(
                      opacity: _frontLayerVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: BottomAppBar(
                        elevation: 0.0,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            backgroundColor: backgroundColor,
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                                  secondary: labelColor,
                                ),
                          ),
                          child: widget.appbarCategory!,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
      title: _BackdropTitle(
          listenable: _controller.view,
          titleColor: labelColor,
          onPress: _toggleBackdropLayerVisibility,
          frontTitle: widget.frontTitle,
          backTitle: widget.backTitle,
          visible: _frontLayerVisible),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.white),
        onPressed: () {
          if (kIsWeb) {
            eventBus.fire(const EventOpenCustomDrawer());
            // LayoutWebCustom.changeStateMenu(true);
          }
          Navigator.pop(context);
        },
      ),
      actions: <Widget>[

        if (widget.showFilter)
          IconButton(
              icon: AnimatedIcon(
                icon: AnimatedIcons.close_menu,
                progress: _controller,
              ),
              color: Colors.white,
              onPressed: _toggleBackdropLayerVisibility),
      ],
    );
    return Scaffold(
      appBar: !isDisplayDesktop(context) ? appBar : null,
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Container(
            
            child: Row(
              children: <Widget>[
                isDisplayDesktop(context)
                    ? Container(
                        width: BackdropConstants.drawerWidth,
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(bottom: 32),
                        color: backgroundColor,
                        child: widget.backLayer,
                      )
                    : const SizedBox(),
                Expanded(
                  child: LayoutBuilder(
                    builder: _buildStack,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortWidget() {
    final sortByData = [
      if (!Config().isWordPress) ...[
        {
          'type': 'date',
          'title': S.of(context).date,
          'icon': CupertinoIcons.calendar,
        },
        if (Config().type != ConfigType.magento) ...[
          {
            'type': 'featured',
            'title': S.of(context).featured,
            'icon': CupertinoIcons.star,
          },
          {
            'type': 'price',
            'title': S.of(context).byPrice,
            'icon': CupertinoIcons.money_dollar,
          }
        ],
        {
          'type': 'on_sale',
          'title': S.of(context).onSale,
          'icon': CupertinoIcons.percent,
        }
      ] else ...[
        {
          'type': 'asc',
          'title': S.of(context).dateASC,
          'icon': CupertinoIcons.sort_down,
        },
        {
          'type': 'desc',
          'title': S.of(context).DateDESC,
          'icon': CupertinoIcons.sort_up,
        }
      ]
    ];
    final selectItem = sortByData.firstWhere(
      (element) => element['type'] == _selectSort,
      orElse: () => sortByData.first,
    );

    return PopupMenuButton<String>(
      icon: Icon(
        selectItem['icon'] as IconData,
        color: labelColor,
        size: 18,
      ),
      onSelected: (String item) {
        _selectSort = item;
        widget.onSort!(item);
      },
      itemBuilder: (BuildContext context) =>
          List<PopupMenuItem<String>>.generate(
        sortByData.length,
        (index) => _buildMenuItem(
          sortByData[index]['icon'] as IconData,
          '${sortByData[index]['title']}',
          '${sortByData[index]['type']}',
          _selectSort == '${sortByData[index]['type']}',
        ),
      ),
    );
  }
}
