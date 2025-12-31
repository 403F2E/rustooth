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

  // Request permissions. Location permission is often required for scanning.
  Future<bool> requestPermissions() async {
    // For Android 12 and above, Bluetooth permissions are required.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission
          .locationWhenInUse, // Often needed for scanning on older Android
    ].request();

    // Check if all required permissions are granted.
    if (statuses[Permission.bluetooth]!.isGranted) {
      return true;
    }
    return false;
  }

  // Start scanning for devices and return the results stream.
  Stream<List<fb.ScanResult>> scanForDevices({Duration? timeout}) {
    // It's good practice to stop any ongoing scan before starting a new one.
    fb.FlutterBluePlus.stopScan();

    // Start scanning with an optional timeout.
    fb.FlutterBluePlus.startScan(timeout: timeout);

    // Return the stream of scan results.
    return fb.FlutterBluePlus.scanResults;
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
}