
import 'package:flutter/material.dart';
import 'package:campus_food_ordering_system/app.dart';
import 'package:campus_food_ordering_system/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}
