import 'dart:async';
import 'dart:io';

class NetworkScanService {
  // gets the device's own local ip address directly from the network
  // interface - this avoids needing location permission entirely,
  // unlike network_info_plus's getWifiIP()
  Future<String?> getDeviceIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      // look specifically for the wifi interface - on android this is
      // almost always named "wlan0". filtering by name avoids accidentally
      // picking up the cellular data connection instead
      for (final interface in interfaces) {
        if (interface.name.toLowerCase().contains('wlan')) {
          for (final addr in interface.addresses) {
            if (!addr.address.startsWith('169.254')) {
              return addr.address;
            }
          }
        }
      }

      // fallback: if no wlan interface was found by name, just avoid
      // the known carrier nat range and take the first reasonable address
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.address.startsWith('169.254') &&
              !addr.address.startsWith('192.0.0')) {
            return addr.address;
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  String? getSubnetPrefix(String? ip) {
    if (ip == null) return null;
    final parts = ip.split('.');
    if (parts.length != 4) return null;
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }

  // list of common ports we check on every candidate address
  static const List<int> commonPorts = [
    21,
    22,
    23,
    80,
    443,
    3389,
    445,
    8000,
    8080,
  ];

  Future<Map<int, bool>> _scanPortsForHost(String ip) async {
    final results = <int, bool>{};

    final futures = commonPorts.map((port) async {
      try {
        // wrap with an explicit .timeout() as a hard backstop - on some
        // android devices, Socket.connect's own timeout parameter doesn't
        // reliably fire when a host goes silent instead of refusing outright
        final socket = await Socket.connect(
          ip,
          port,
        ).timeout(const Duration(milliseconds: 500));
        socket.destroy();
        results[port] = true;
      } catch (e) {
        results[port] = false;
      }
    });

    await Future.wait(futures);
    return results;
  }

  // scans a range of addresses directly, port by port - no separate
  // "is this host alive" pre-check, since devices with no server running
  // never respond to a simple liveness probe anyway
  Future<Map<String, List<int>>> scanNetwork(
    String subnetPrefix, {
    int maxHost = 254,
    void Function(int checked, int total)? onProgress,
  }) async {
    final results = <String, List<int>>{};
    const hostBatchSize =
        10; // scan up to 10 addresses at once, not one at a time

    for (int start = 1; start <= maxHost; start += hostBatchSize) {
      final end = (start + hostBatchSize - 1).clamp(1, maxHost);
      final batchFutures = <Future<void>>[];

      for (int i = start; i <= end; i++) {
        final ip = '$subnetPrefix.$i';
        batchFutures.add(
          _scanPortsForHost(ip).then((portResults) {
            final openPorts = portResults.entries
                .where((e) => e.value)
                .map((e) => e.key)
                .toList();
            if (openPorts.isNotEmpty) {
              results[ip] = openPorts;
            }
          }),
        );
      }

      await Future.wait(batchFutures);
      onProgress?.call(end, maxHost);
    }

    return results;
  }
}
