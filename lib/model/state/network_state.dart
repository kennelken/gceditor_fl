import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final networkStateProvider = ChangeNotifierProvider((_) => NetworkStateNotifier(NetworkState()));

class NetworkState {
  int? openPort;

  NetworkState();
}

class NetworkStateNotifier extends ChangeNotifier {
  late NetworkState state;
  NetworkStateNotifier(this.state);

  void setOpenPort(int? port) {
    state.openPort = port;
    notifyListeners();
  }
}
