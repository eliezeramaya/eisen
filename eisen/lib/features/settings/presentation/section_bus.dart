import 'package:flutter/widgets.dart';

typedef JumpTo = void Function(String section);

class SettingsSectionBus extends InheritedWidget {
  final JumpTo jumpTo;
  const SettingsSectionBus({required this.jumpTo, required super.child, super.key});
  static SettingsSectionBus of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsSectionBus>()!;
  @override
  bool updateShouldNotify(covariant SettingsSectionBus old) => jumpTo != old.jumpTo;
}

