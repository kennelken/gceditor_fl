import 'dart:math';

import 'package:dartx/dartx.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/log_state.dart';
import 'package:gceditor/model/state/network_state.dart';
import 'package:tcp_scanner/tcp_scanner.dart';

class NetworkManager {
  static NetworkManager? _instance;
  // ignore: prefer_constructors_over_static_methods
  static NetworkManager get instance {
    _instance ??= NetworkManager();
    return _instance!;
  }

  Future refreshFreePorts() async {
    final range = IntRange(Config.portMin, Config.portMax).toList();

    final ports = await checkPorts(range, <int>[]);
    providerContainer.read(networkStateProvider.notifier).setOpenPort(ports[0]);
  }

  Future<List<int?>> checkPorts(List<int> rangeA, List<int> rangeB) async {
    final result = <int?>[null, null];

    var emergencyQuit = 100;
    var i = 0;
    final portsToCheck = <int>[];
    var retriesCount = 0;

    outer:
    while (--emergencyQuit > 0) {
      final step = Config.portScanningStep * 2 * pow(2, retriesCount);
      portsToCheck.clear();
      for (; portsToCheck.length < step; i++) {
        if (i >= rangeA.length && i >= rangeB.length) //
          break;

        if (i < rangeA.length) portsToCheck.add(rangeA[i]);
        if (i < rangeB.length) portsToCheck.add(rangeB[i]);
      }
      if (portsToCheck.isEmpty) break;

      TcpScannerTaskReport? scanResult;
      final scanTask = TcpScannerTask(
        Config.defaultIp,
        portsToCheck,
        socketTimeout: const Duration(milliseconds: 500),
      );
      try {
        await Future.any([
          Future(() async {
            scanResult = await scanTask.start();
          }),
          Future.delayed(const Duration(milliseconds: 1200))
        ]);
      } catch (error, callstack) {
        providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'failed to find open port.\nclasstack: $callstack'));
        try {
          scanTask.cancel();
        } catch (error2, callstack) {
          providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'failed to cancel scan task.\nclasstack: $callstack'));
        }
        break outer;
      }

      if (scanResult == null) {
        providerContainer.read(logStateProvider).addMessage(LogEntry(LogLevel.warning, 'failed to find open port. probably timed out.'));
        return result;
      }

      if (scanResult!.status != TcpScannerTaskReportStatus.finished) //
        break;
      for (final closedPort in scanResult!.closedPorts) {
        if (result[0] == null) {
          if (rangeA.contains(closedPort)) //
            result[0] = closedPort;
        }
        if (result[1] == null) {
          if (rangeB.contains(closedPort)) //
            result[1] = closedPort;
        }
        if ((result[0] != null || rangeA.isEmpty) && //
            (result[1] != null || rangeB.isEmpty)) //
          break outer;
      }
      retriesCount++;
    }

    return result;
  }
}
