import 'dart:developer';

import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

void main() {
  runApp(RemoteApp());
}

class RemoteApp extends StatelessWidget {
  const RemoteApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PC Remote Control',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
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

  // This would be replaced with your Rust Bluetooth implementation
  void _connectToDevice() {
    setState(() {
      _isConnected = true;
      _connectionStatus = 'Connected';
    });
    // Simulate connection process
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isConnected = true;
          _connectionStatus = 'Connected to PC';
        });
      }
    });
  }

  void _disconnectFromDevice() {
    setState(() {
      _isConnected = false;
      _connectionStatus = 'Disconnected';
    });
  }

  void _sendCommand(String command) {
    // This would send the command via Bluetooth using your Rust implementation
    log('Sending command: $command');
    // Here you would implement the Bluetooth communication
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PC Remote Control'),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
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
          // Mode selector
          Row(
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
                        : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('Remote Control'),
                  ),
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
                        : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('Keyboard Mode'),
                  ),
                ),
              ),
            ],
          ),

          // Connection button
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: _isConnected
                ? ElevatedButton(
                    onPressed: _disconnectFromDevice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Disconnect'),
                  )
                : ElevatedButton(
                    onPressed: _connectToDevice,
                    child: Text('Connect to PC'),
                  ),
          ),

          // Content based on selected mode
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                RemoteControlMode(sendCommand: _sendCommand),
                KeyboardMode(sendCommand: _sendCommand),
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
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Power button
          Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: ElevatedButton(
              onPressed: () => sendCommand('POWER'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
              ),
              child: Text('Power'),
            ),
          ),

          // Navigation pad
          Padding(
            padding: EdgeInsets.only(bottom: 16.0),
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
                    SizedBox(width: 48.0),
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

          // Media controls
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
      padding: EdgeInsets.all(4.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: CircleBorder(),
          padding: EdgeInsets.all(16.0),
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
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Text input
          TextField(
            controller: _textController,
            focusNode: _textFocusNode,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Type text to send',
              suffixIcon: IconButton(
                icon: Icon(Icons.send),
                onPressed: _sendText,
              ),
            ),
            onSubmitted: (_) => _sendText(),
          ),
          SizedBox(height: 16.0),

          // Special keys
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
          SizedBox(height: 16.0),

          // Mouse controls
          Text('Mouse Controls', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => widget.sendCommand('MOUSE:LEFT_CLICK'),
                child: Text('Left Click'),
              ),
              ElevatedButton(
                onPressed: () => widget.sendCommand('MOUSE:RIGHT_CLICK'),
                child: Text('Right Click'),
              ),
              ElevatedButton(
                onPressed: () => widget.sendCommand('MOUSE:SCROLL_CLICK'),
                child: Text('Middle Click'),
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

// Custom Chip that acts like a button
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
        backgroundColor: Theme.of(context).primaryColor.withValues(),
      ),
    );
  }
}
