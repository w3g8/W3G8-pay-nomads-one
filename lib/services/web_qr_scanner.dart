// import 'dart:async'; // unused
import 'dart:js_interop';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Web-compatible QR scanner using browser camera API + jsQR
class WebQRScannerOverlay extends StatefulWidget {
  final void Function(String code) onDetect;
  final VoidCallback onClose;

  const WebQRScannerOverlay({
    super.key,
    required this.onDetect,
    required this.onClose,
  });

  @override
  State<WebQRScannerOverlay> createState() => _WebQRScannerOverlayState();
}

class _WebQRScannerOverlayState extends State<WebQRScannerOverlay> {
  bool _starting = true;
  String? _error;
  bool _detected = false;

  @override
  void initState() {
    super.initState();
    _startScanner();
  }

  @override
  void dispose() {
    _stopScanner();
    super.dispose();
  }

  void _startScanner() {
    if (!kIsWeb) return;

    // Show the container
    final container = web.document.getElementById('qr-scanner-container') as web.HTMLElement?;
    if (container != null) {
      container.style.setProperty('display', 'block');
    }

    // Set up the callback
    _setJSCallback(((JSString code) {
      if (!_detected) {
        _detected = true;
        final value = code.toDart;
        _stopScanner();
        widget.onDetect(value);
      }
    }).toJS);

    // Start the scanner
    _startJSScanner().toDart.then((result) {
      if (mounted) {
        setState(() {
          _starting = false;
          if (result != true.toJS) {
            _error = 'Camera access denied. Please allow camera permission.';
          }
        });
      }
    });
  }

  void _stopScanner() {
    if (!kIsWeb) return;
    _stopJSScanner();
    final container = web.document.getElementById('qr-scanner-container') as web.HTMLElement?;
    if (container != null) {
      container.style.setProperty('display', 'none');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // The video is rendered by JS in the HTML container
          // We overlay Flutter UI on top
          if (_starting)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Starting camera...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),

          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt, size: 48, color: Colors.white54),
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() { _error = null; _starting = true; _detected = false; });
                        _startScanner();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),

          // Scanning overlay
          if (!_starting && _error == null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 250, height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Point camera at QR code',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),

          // Close button
          Positioned(
            top: 40, left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () {
                _stopScanner();
                widget.onClose();
              },
            ),
          ),
        ],
      ),
    );
  }
}

@JS('window._qrScanner.start')
external JSPromise _startJSScanner();

@JS('window._qrScanner.stop')
external void _stopJSScanner();

// Helper to set the callback
@JS('_setQRCallback')
external void _setJSCallback(JSFunction callback);

// We need to add this helper function to the JS side
// It's simpler than trying to pass a callback through start()
