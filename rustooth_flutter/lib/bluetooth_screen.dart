import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fb;

class BluetoothScreen extends StatefulWidget {
  final bool isScanning;
  final List<fb.ScanResult> scanResults;
  final List<fb.BluetoothDevice> bondedDevices; // New field for bonded devices
  final VoidCallback toggleScan;
  final Function(fb.BluetoothDevice) connectToDevice;
  final bool isConnected;
  final fb.BluetoothDevice? connectedDevice;
  final VoidCallback onDisconnect;

  const BluetoothScreen({
    super.key,
    required this.isScanning,
    required this.scanResults,
    required this.bondedDevices, // Require bonded devices list
    required this.toggleScan,
    required this.connectToDevice,
    required this.isConnected,
    this.connectedDevice,
    required this.onDisconnect,
  });

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  String _getDeviceName(fb.ScanResult result) {
    if (result.device.platformName.isNotEmpty) {
      return result.device.platformName;
    } else if (result.advertisementData.advName.isNotEmpty) {
      return result.advertisementData.advName;
    } else {
      return 'Unknown Device';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isConnected && widget.connectedDevice != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Connected to ${widget.connectedDevice!.platformName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('ID: ${widget.connectedDevice!.remoteId}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.onDisconnect,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Disconnect'),
            ),
          ],
        ),
      );
    }

    final filteredResults = widget.scanResults.where((result) {
      if (_searchQuery.isEmpty) return true;
      final remoteId = result.device.remoteId.toString().toLowerCase();
      final name = _getDeviceName(result).toLowerCase();
      return remoteId.contains(_searchQuery) || name.contains(_searchQuery);
    }).toList();

    // Filter bonded devices based on search query
    final filteredBonded = widget.bondedDevices.where((device) {
      if (_searchQuery.isEmpty) return true;
      final remoteId = device.remoteId.toString().toLowerCase();
      final name = device.platformName.toLowerCase();
      return remoteId.contains(_searchQuery) || name.contains(_searchQuery);
    }).toList();


    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search MAC Address or Name',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.toggleScan,
              child: Text(widget.isScanning ? 'Stop Scan' : 'Start Scan'),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
               if (filteredBonded.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text("Paired Devices", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  ...filteredBonded.map((device) => ListTile(
                    title: Text(device.platformName.isNotEmpty ? device.platformName : "Unknown Paired Device"),
                    subtitle: Text(device.remoteId.toString()),
                    trailing: ElevatedButton(
                      child: const Text('Connect'),
                      onPressed: () => widget.connectToDevice(device),
                    ),
                  )),
                  const Divider(),
               ],
               
               if (filteredResults.isNotEmpty || widget.isScanning) ...[
                 const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text("Available Devices", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                 ...filteredResults.map((result) {
                    final deviceName = _getDeviceName(result);
                    return ListTile(
                      title: Text(deviceName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(result.device.remoteId.toString()),
                          Text("Signal: ${result.rssi} dBm", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      trailing: ElevatedButton(
                        child: const Text('Connect'),
                        onPressed: () => widget.connectToDevice(result.device),
                      ),
                    );
                 }),
               ] else if (filteredBonded.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text("No devices found. Start scanning.")),
                  )
               ]
            ],
          ),
        ),
      ],
    );
  }
}
