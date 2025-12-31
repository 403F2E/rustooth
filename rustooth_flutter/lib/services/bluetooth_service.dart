import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fb;
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  // Check if Bluetooth is supported by the device hardware.
  Future<bool> isBluetoothSupported() async {
    return await fb.FlutterBluePlus.isSupported;
  }

  // Check the current Bluetooth adapter state.
  // Note: The initial state on iOS is often 'unknown'.
  Stream<fb.BluetoothAdapterState> get bluetoothState {
    return fb.FlutterBluePlus.adapterState;
  }

  // Check if bluetooth is enabled
  Future<bool> isBluetoothEnabled() async {
    return await fb.FlutterBluePlus.adapterState.first == fb.BluetoothAdapterState.on;
  }

  // Get currently connected devices
  List<fb.BluetoothDevice> get connectedDevices {
    return fb.FlutterBluePlus.connectedDevices;
  }

  // Get a list of bonded (paired) devices.
  Future<List<fb.BluetoothDevice>> getBondedDevices() async {
    return await fb.FlutterBluePlus.bondedDevices;
  }

  // Request permissions. Location permission is often required for scanning.
  Future<bool> requestPermissions() async {
    // For Android 12 and above, Bluetooth permissions are required.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // Check if all required permissions are granted.
    if (statuses[Permission.bluetoothScan]!.isGranted &&
        statuses[Permission.location]!.isGranted) {
      if (await isBluetoothEnabled()) {
        return true;
      } else {
        print("Bluetooth is not enabled.");
        return false;
      }
    }
    print("Permissions not granted: $statuses");
    return false;
  }

  // Start scanning for devices and return the results stream.
  Stream<List<fb.ScanResult>> scanForDevices({Duration? timeout}) {
    // It's good practice to stop any ongoing scan before starting a new one.
    fb.FlutterBluePlus.stopScan();

    // Start scanning with an optional timeout.
    fb.FlutterBluePlus.startScan(timeout: timeout);

    // Return the stream of scan results and print them for debugging.
    return fb.FlutterBluePlus.scanResults.map((results) {
      print("--- Found ${results.length} devices ---");
      for (var result in results) {
        String name = result.device.platformName.isNotEmpty
            ? result.device.platformName
            : "Unknown Device";
        print("$name [${result.device.remoteId}]");
      }
      return results;
    });
  }

  // Stop scanning for devices.
  void stopScan() {
    fb.FlutterBluePlus.stopScan();
  }

  // Connect to a device.
  Future<void> connectToDevice(fb.BluetoothDevice device) async {
    await device.connect();
  }

  // Disconnect from a device.
  Future<void> disconnectDevice(fb.BluetoothDevice device) async {
    await device.disconnect();
  }

  // Discover services of a connected device.
  // Important: You must call this after every connection.
  Future<List<fb.BluetoothService>> discoverServices(
    fb.BluetoothDevice device,
  ) async {
    return await device.discoverServices();
  }

  // Find a writable characteristic
  Future<fb.BluetoothCharacteristic?> findWritableCharacteristic(fb.BluetoothDevice device) async {
    try {
      List<fb.BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            return characteristic;
          }
        }
      }
    } catch (e) {
      print("Error finding services: $e");
    }
    return null;
  }
}
