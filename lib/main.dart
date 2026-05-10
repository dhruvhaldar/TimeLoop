import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'core/app_runtime.dart';
import 'core/platform_service.dart';
import 'ui/layout_orchestrator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Platform Services (Notifications, Window Management)
  await PlatformService.instance.init();
  
  // Initialize App Runtime (Logic and state container)
  final runtime = AppRuntime();
  
  runApp(TimeLoopApp(runtime: runtime));
}

class TimeLoopApp extends StatelessWidget {
  final AppRuntime runtime;
  
  const TimeLoopApp({super.key, required this.runtime});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimeLoop : Advanced Stopwatch and Repetitive Reminders',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto', // Default fallback
      ),
      home: LayoutOrchestrator(runtime: runtime),
    );
  }
}
