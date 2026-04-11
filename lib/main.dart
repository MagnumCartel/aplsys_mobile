import 'package:flutter/material.dart';
import 'login.dart';
import 'supabase_config.dart';
import 'topbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();

  final session = SupabaseConfig.client.auth.currentSession;

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: session == null
          ? const LoginScreen()
          : LeaveApp(userName: session.user.email ?? ''),
    ),
  );
}
