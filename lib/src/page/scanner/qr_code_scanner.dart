import 'package:flutter/material.dart';

import 'package:mobile_scanner/mobile_scanner.dart';

import '../../i18n.dart';

class QrCodeScannerPage extends StatefulWidget {
  const QrCodeScannerPage({super.key});

  static const routeName = "/scanner_code";

  @override
  State<QrCodeScannerPage> createState() => _QrCodeScannerPageState();
}

class _QrCodeScannerPageState extends State<QrCodeScannerPage> {
  bool scannered = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(I18n.of(context)!.scan_code),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (BarcodeCapture barcodes) {
              if (mounted) {
                final barcode = barcodes.barcodes.firstOrNull;
                if (!scannered && barcode != null) {
                  scannered = true;
                  Navigator.of(context).pop(barcode.displayValue);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
