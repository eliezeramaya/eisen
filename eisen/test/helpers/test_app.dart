import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget buildTestApp({
  required Widget child,
  ProviderContainer? container,
}) {
  final app = MaterialApp(home: Scaffold(body: child));
  if (container == null) return app;
  return UncontrolledProviderScope(
    container: container,
    child: app,
  );
}
