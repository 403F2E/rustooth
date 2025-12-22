import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fb;

class BluetoothScreen extends StatelessWidget {
  final bool isScanning;
  final List<fb.ScanResult> scanResults;
  final VoidCallback toggleScan;
  final Function(fb.BluetoothDevice) connectToDevice;

  const BluetoothScreen({
    super.key,
    required this.isScanning,
    required this.scanResults,
    required this.toggleScan,
    required this.connectToDevice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: toggleScan,
            child: Text(isScanning ? 'Stop Scan' : 'Start Scan'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: scanResults.length,
            itemBuilder: (context, index) {
              final result = scanResults[index];
              final deviceName = result.device.platformName.isNotEmpty
                  ? result.device.platformName
                  : 'Unknown Device';
              return ListTile(
                title: Text(deviceName),
                subtitle: Text(result.device.remoteId.toString()),
                trailing: ElevatedButton(
                  child: const Text('Connect'),
                  onPressed: () => connectToDevice(result.device),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
