import 'dart:developer';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fb;
import 'package:rustooth_flutter/bluetooth_screen.dart';

import 'services/bluetooth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PC Remote Control',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isConnected = false;
  String _connectionStatus = 'Disconnected';

  final BluetoothService _btService = BluetoothService();
  fb.BluetoothDevice? _connectedDevice;
  fb.BluetoothCharacteristic? _writableCharacteristic;
  StreamSubscription? _scanSubscription;
  List<fb.ScanResult> _scanResults = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _checkConnectedDevices();
  }

  void _checkConnectedDevices() async {
    try {
      // 1. Check devices already connected to the system
      List<fb.BluetoothDevice> connected = _btService.connectedDevices;
      if (connected.isNotEmpty) {
        log("Found already connected device: ${connected.first.remoteId}");
        _connectToDevice(connected.first);
        return;
      }

      // 2. If no active connection, check paired/bonded devices
      if (await _btService.isBluetoothSupported()) {
          List<fb.BluetoothDevice> bondedDevices = await _btService.getBondedDevices();
          if (bondedDevices.isNotEmpty) {
             log("Found bonded devices: ${bondedDevices.length}");
             // Note: Bonded devices are not necessarily connected. 
             // We can list them or try to connect to a specific one if known.
             // For now, we will just log them. In a real app, you might want 
             // to try connecting to the last used one.
             for(var device in bondedDevices) {
                log("Bonded: ${device.platformName} (${device.remoteId})");
             }
          }
      }

    } catch (e) {
      log("Error checking connected devices: $e");
    }
  }

  void _toggleScan() async {
    if (_isScanning) {
      _btService.stopScan();
      setState(() {
        _isScanning = false;
        _connectionStatus = 'Scan stopped';
      });
    } else {
      setState(() {
        _connectionStatus = 'Requesting permissions...';
      });

      final hasPermissions = await _btService.requestPermissions();
      if (!hasPermissions) {
        setState(() {
          _connectionStatus = 'Bluetooth permission denied';
        });
        return;
      }

      setState(() {
        _connectionStatus = 'Scanning for devices...';
        _isScanning = true;
        _scanResults = [];
      });

      final scanStream = _btService.scanForDevices(timeout: const Duration(minutes: 10));

      _scanSubscription?.cancel();
      _scanSubscription = scanStream.listen(
            (results) {
          setState(() {
            _scanResults = results;
          });
        },
        onError: (err) {
          setState(() {
            _connectionStatus = 'Scan error: $err';
            _isScanning = false;
          });
        },
        onDone: () {
          if (mounted && _isScanning) {
             setState(() {
               _isScanning = false;
               _connectionStatus = _scanResults.isEmpty ? 'No devices found' : 'Scan complete';
             });
          }
        },
      );
    }
  }

  void _connectToDevice(fb.BluetoothDevice device) async {
    _btService.stopScan();
    await _scanSubscription?.cancel();

    setState(() {
      _isScanning = false;
      _connectionStatus = 'Connecting to ${device.platformName}...';
    });

    try {
      await _btService.connectToDevice(device);
      
      final characteristic = await _btService.findWritableCharacteristic(device);

      _connectedDevice = device;
      
      if (characteristic != null) {
        _writableCharacteristic = characteristic;
        setState(() {
          _isConnected = true;
          _connectionStatus = 'Connected to ${device.platformName}';
          _scanResults = [];
        });
      } else {
        log("No writable characteristic found on ${device.platformName}");
        setState(() {
           _isConnected = true;
           _connectionStatus = 'Connected (Read-only)';
           _scanResults = [];
        });
      }
      
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection failed: $e';
        _isConnected = false;
        _connectedDevice = null;
        _writableCharacteristic = null;
      });
    }
  }

  void _disconnectFromDevice() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    if (_connectedDevice != null) {
      try {
        await _btService.disconnectDevice(_connectedDevice!);
      } catch (e) {
        log('Disconnect error: $e');
      }
    }

    setState(() {
      _connectedDevice = null;
      _writableCharacteristic = null;
      _isConnected = false;
      _connectionStatus = 'Disconnected';
    });
  }

  void _sendCommand(String command) async {
    log('Sending command: $command');
    if (_writableCharacteristic != null) {
      try {
        await _writableCharacteristic!.write(utf8.encode(command));
      } catch (e) {
        log('Error sending command: $e');
        setState(() {
           _connectionStatus = 'Error sending command';
        });
      }
    } else if (!_isConnected) {
        log('Not connected');
    } else {
        log('No writable characteristic');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PC Remote Control'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                _connectionStatus,
                style: TextStyle(
                  color: _isConnected ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56.0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _currentIndex = 0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentIndex == 0
                          ? Colors.blue[700]
                          : Colors.grey[300],
                      foregroundColor: _currentIndex == 0
                          ? Colors.white
                          : Colors.deepPurple,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text('Remote Control'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _currentIndex = 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentIndex == 1
                          ? Colors.blue[700]
                          : Colors.grey[300],
                      foregroundColor: _currentIndex == 1
                          ? Colors.white
                          : Colors.deepPurple,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text('Keyboard Mode'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _currentIndex = 2),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentIndex == 2
                          ? Colors.blue[700]
                          : Colors.grey[300],
                      foregroundColor: _currentIndex == 2
                          ? Colors.white
                          : Colors.deepPurple,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text('Bluetooth'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                RemoteControlMode(sendCommand: _sendCommand),
                KeyboardMode(sendCommand: _sendCommand),
                BluetoothScreen(
                  isScanning: _isScanning,
                  scanResults: _scanResults,
                  toggleScan: _toggleScan,
                  connectToDevice: _connectToDevice,
                  isConnected: _isConnected,
                  connectedDevice: _connectedDevice,
                  onDisconnect: _disconnectFromDevice,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RemoteControlMode extends StatelessWidget {
  final Function(String) sendCommand;

  const RemoteControlMode({super.key, required this.sendCommand});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ElevatedButton(
              onPressed: () => sendCommand('POWER'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
              ),
              child: const Text('Power'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RemoteButton(
                      onPressed: () => sendCommand('UP'),
                      icon: Icons.arrow_upward,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RemoteButton(
                      onPressed: () => sendCommand('LEFT'),
                      icon: Icons.arrow_back,
                    ),
                    const SizedBox(width: 48.0),
                    RemoteButton(
                      onPressed: () => sendCommand('RIGHT'),
                      icon: Icons.arrow_forward,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RemoteButton(
                      onPressed: () => sendCommand('DOWN'),
                      icon: Icons.arrow_downward,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RemoteButton(
                onPressed: () => sendCommand('VOL_UP'),
                icon: Icons.volume_up,
              ),
              RemoteButton(
                onPressed: () => sendCommand('VOL_DOWN'),
                icon: Icons.volume_down,
              ),
              RemoteButton(
                onPressed: () => sendCommand('MUTE'),
                icon: Icons.volume_off,
              ),
              RemoteButton(
                onPressed: () => sendCommand('PLAY_PAUSE'),
                icon: Icons.play_arrow,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RemoteButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const RemoteButton({super.key, required this.onPressed, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16.0),
        ),
        child: Icon(icon, size: 24.0),
      ),
    );
  }
}

class KeyboardMode extends StatefulWidget {
  final Function(String) sendCommand;

  const KeyboardMode({super.key, required this.sendCommand});

  @override
  KeyboardModeState createState() => KeyboardModeState();
}

class KeyboardModeState extends State<KeyboardMode> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  void _sendText() {
    if (_textController.text.isNotEmpty) {
      widget.sendCommand('TEXT:${_textController.text}');
      _textController.clear();
    }
  }

  void _sendSpecialKey(String key) {
    widget.sendCommand('KEY:$key');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _textController,
            focusNode: _textFocusNode,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Type text to send',
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendText,
              ),
            ),
            onSubmitted: (_) => _sendText(),
          ),
          const SizedBox(height: 16.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              ActionChip(
                label: 'Enter',
                onPressed: () => _sendSpecialKey('ENTER'),
              ),
              ActionChip(label: 'Tab', onPressed: () => _sendSpecialKey('TAB')),
              ActionChip(label: 'Esc', onPressed: () => _sendSpecialKey('ESC')),
              ActionChip(
                label: 'Backspace',
                onPressed: () => _sendSpecialKey('BACKSPACE'),
              ),
              ActionChip(
                label: 'Ctrl+C',
                onPressed: () => _sendSpecialKey('CTRL_C'),
              ),
              ActionChip(
                label: 'Ctrl+V',
                onPressed: () => _sendSpecialKey('CTRL_V'),
              ),
              ActionChip(
                label: 'Alt+Tab',
                onPressed: () => _sendSpecialKey('ALT_TAB'),
              ),
              ActionChip(label: 'Win', onPressed: () => _sendSpecialKey('WIN')),
            ],
          ),
          const SizedBox(height: 16.0),
          const Text('Mouse Controls', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => widget.sendCommand('MOUSE:LEFT_CLICK'),
                child: const Text('Left Click'),
              ),
              ElevatedButton(
                onPressed: () => widget.sendCommand('MOUSE:RIGHT_CLICK'),
                child: const Text('Right Click'),
              ),
              ElevatedButton(
                onPressed: () => widget.sendCommand('MOUSE:SCROLL_CLICK'),
                child: const Text('Middle Click'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }
}

class ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const ActionChip({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Chip(
        label: Text(label),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
