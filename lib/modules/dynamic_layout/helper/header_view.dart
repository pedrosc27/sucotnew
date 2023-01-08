import 'package:flutter/material.dart';

import '../../../common/tools/adaptive_tools.dart';
import '../../../generated/l10n.dart';
import 'countdown_timer.dart';

class HeaderView extends StatelessWidget {
  final String? headerText;
  final VoidCallback? callback;
  final bool showSeeAll;
  final bool showCountdown;
  final Duration countdownDuration;
  final double? verticalMargin;
  final double? horizontalMargin;

  const HeaderView({
    this.headerText,
    this.showSeeAll = false,
    Key? key,
    this.callback,
    this.verticalMargin = 6.0,
    this.horizontalMargin,
    this.showCountdown = false,
    this.countdownDuration = const Duration(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    var isDesktop = isDisplayDesktop(context);

    return SizedBox(
      width: screenSize.width,
      child: Container(
        color: Theme.of(context).backgroundColor,
        
        padding: EdgeInsets.only(
          left: horizontalMargin ?? 16.0,
          top: 16,
          right: horizontalMargin ?? 8.0,
          bottom: 16,
        ),
        child: Row(
          textBaseline: TextBaseline.alphabetic,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDesktop) ...[
                    const Divider(height: 50, indent: 30, endIndent: 30),
                  ],
                  const Text(
                    'Productos',
                    style:  TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontFamily: 'NeoMedium',
                        fontWeight: FontWeight.w700)
                  ),
                  if (showCountdown)
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
                        CountDownTimer(countdownDuration),
                      ],
                    ),
                  if (isDesktop) const SizedBox(height: 10),
                ],
              ),
            ),
           
          ],
        ),
      ),
    );
  }
}
