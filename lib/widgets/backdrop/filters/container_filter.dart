import 'package:flutter/material.dart';

import '../../../common/config.dart';

class ContainerFilter extends StatelessWidget {
  final String? text;
  final Widget? child;
  final EdgeInsets margin;
  final EdgeInsets? padding;
  final bool isSelected;

  const ContainerFilter({
    Key? key,
    this.text,
    this.isSelected = false,
    this.child,
    this.margin = EdgeInsets.zero,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var _primaryBackground = kAdvanceConfig['enableProductBackdrop'] ?? false
        ? Colors.white
        : Theme.of(context).primaryColor.withOpacity(0.2);
    var _primaryText = Theme.of(context).primaryColor;
    var _secondColor = Theme.of(context).colorScheme.secondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: margin,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? _primaryBackground : _secondColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? _primaryText : _secondColor.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Center(
        child: child ??
            Text(
              text ?? '',
              style: Theme.of(context).textTheme.bodyText1!.copyWith(
                    color: isSelected
                        ? _primaryText
                        : _secondColor.withOpacity(0.8),
                    letterSpacing: 1.2,
                  ),
            ),
      ),
    );
  }
}
