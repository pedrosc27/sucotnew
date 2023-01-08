import 'package:flutter/material.dart';
import 'package:fstore/common/tools/navigate_tools.dart';
import 'package:provider/provider.dart';

import '../../menu/index.dart' show FluxAppBar;
import '../../models/index.dart' show AppModel;
import '../../modules/dynamic_layout/index.dart' show AppBarConfig;

mixin AppBarMixin<T extends StatefulWidget> on State<T> {
  AppBarConfig? get appBar =>
      context.select((AppModel model) => model.appConfig?.appBar);

  bool showAppBar(String routeName) {
    if (appBar?.enable ?? false) {
      return appBar?.shouldShowOn(routeName) ?? false;
    }
    return false;
  }

  AppBar get appBarWidget => AppBar(
    toolbarHeight: 300,
        titleSpacing: 0,
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).backgroundColor,
        title: Container(
          height: 100,
          margin: const EdgeInsets.only(top: 20.0),
      padding: const EdgeInsets.only(top: 16, bottom: 26, right: 16, left: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Image.asset(
            'assets/images/logotipo.png',
            width: 140,
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, 'filter');
            },
            child: Container(
              height: 65,
              width: 65,
              decoration: BoxDecoration(
                  color: const Color(0xFFcc0000), borderRadius: BorderRadius.circular(15)),
              padding: const EdgeInsets.all(8),
              child: IconButton(
                icon: Image.asset('assets/images/filter.png'),
                iconSize: 90,
                onPressed: () {
                  NavigateTools.onTapOpenDrawerMenu(context);
                },
              ),
            ),
          ),
        ],
      ),
    ),
      );

  SliverAppBar get sliverAppBarWidget => SliverAppBar(
        toolbarHeight: 80,
        snap: true,
        pinned: true,
        floating: true,
        titleSpacing: 0,
        elevation: 0,
        forceElevated: true,
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).backgroundColor,
        title: Container(
          margin: EdgeInsets.only(top: 10),
      padding: const EdgeInsets.only(top: 16, bottom: 26, right: 16, left: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
    
          Image.asset(
            'assets/images/logotipo.png',
            width: 140,
          ),
          GestureDetector(
            onTap: () {
              NavigateTools.onTapOpenDrawerMenu(context);
            },
            child: Container(
              height: 65,
              width: 65,
              decoration: BoxDecoration(
                  color: const Color(0xFFcc0000), borderRadius: BorderRadius.circular(15)),
              padding: const EdgeInsets.all(8),
              child: IconButton(
                icon: Image.asset('assets/images/filter.png'),
                iconSize: 90,
                onPressed: () {
                  NavigateTools.onTapOpenDrawerMenu(context);
                },
              ),
            ),
          ),

        ],
      ),
    ),
      );
}
