import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fb;
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  // UUIDs matching the Rust Server
  static const String SERVER_SERVICE_UUID = "12345678-1234-5678-1234-56789abc0000";
  static const String SERVER_CHAR_UUID    = "12345678-1234-5678-1234-56789abc0001";

  // Check if Bluetooth is supported by the device hardware.
  Future<bool> isBluetoothSupported() async {
    return await fb.FlutterBluePlus.isSupported;
  }

  // Check the current Bluetooth adapter state.
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

  // Request permissions.
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothScan]!.isGranted &&
        statuses[Permission.location]!.isGranted) {
      if (await isBluetoothEnabled()) {
        return true;
      }
    }
    return false;
  }

  // Start scanning for devices. 
  // Updated to prefer our specific service UUID for faster/cleaner scanning.
  Stream<List<fb.ScanResult>> scanForDevices({Duration? timeout}) {
    fb.FlutterBluePlus.stopScan();

    // We scan for EVERYTHING to be safe, but you could add 
    // withServices: [fb.Guid(SERVER_SERVICE_UUID)] to strictly find only your PC.
    fb.FlutterBluePlus.startScan(timeout: timeout);

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
        // STRICT CHECK: Only look inside our specific service
        if (service.uuid.toString().toLowerCase() == SERVER_SERVICE_UUID.toLowerCase()) {
          for (var c in service.characteristics) {
            if (c.uuid.toString().toLowerCase() == SERVER_CHAR_UUID.toLowerCase()) {
              print("Found correct Target Characteristic: ${c.uuid}");
              return c;
            }
          }
        }
      }
      print("Target Characteristic $SERVER_CHAR_UUID NOT found on this device.");

      // I removed the fallback loop here.
      // Do NOT return random writable characteristics.

    } catch (e) {
      print("Error finding services: $e");
    }
    return null;
  }
}
