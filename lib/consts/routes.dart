import 'package:flutter/material.dart';
import 'package:gceditor/screens/client_screen.dart';
import 'package:gceditor/screens/landing_screen.dart';
import 'package:gceditor/screens/loading_screen.dart';
import 'package:gceditor/screens/server_screen.dart';

class Screen {
  static const String loading = '/';
  static const String landing = '/home';
  static const String client = '/client';
  static const String server = '/server';

  static Set<String> allScreens = {
    loading,
    landing,
    client,
    server,
  };
}

Widget getWidgetByScreen(String pageName) {
  switch (pageName) {
    case Screen.loading:
      return const LoadingScreen();

    case Screen.landing:
      return const LandingScreen();

    case Screen.client:
      return const ClientScreen();

    case Screen.server:
      return const ServerScreen();

    default:
      throw Exception('Unexpected route $pageName');
  }
}
