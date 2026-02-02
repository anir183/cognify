import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';

class QRScannerScreen extends StatefulWidget {
  final Function(String) onScanned;

  const QRScannerScreen({
    super.key,
    required this.onScanned,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _scanned = false;
  bool _isFlashOn = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _scanned = true);
        widget.onScanned(barcode.rawValue!);
        Navigator.of(context).pop();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Mobile Scanner View
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),

          // Overlay Scrim & Cutout
          CustomPaint(
            painter: ScannerOverlayPainter(
              borderColor: AppTheme.primaryCyan,
              borderRadius: 16,
              borderLength: 40,
              borderWidth: 8,
              cutOutSize: MediaQuery.of(context).size.width * 0.8,
            ),
            child: Container(),
          ),

          // Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                    ),
                  ),

                  // Torch Toggle
                  IconButton(
                    onPressed: () {
                      controller.toggleTorch();
                      setState(() {
                        _isFlashOn = !_isFlashOn;
                      });
                    },
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                    Colors.black,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: AppTheme.primaryCyan,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Scan Certificate QR Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Position the QR code within the frame',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Scanner Overlay
class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;

  ScannerOverlayPainter({
    required this.borderColor,
    required this.borderRadius,
    required this.borderLength,
    required this.borderWidth,
    required this.cutOutSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = cutOutSize;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;
    final Rect scanRect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Draw semi-transparent background
    final Paint backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final Path backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          scanRect,
          Radius.circular(borderRadius),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Draw borders
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final Path borderPath = Path();

    // Top-left
    borderPath.moveTo(left, top + borderLength);
    borderPath.lineTo(left, top + borderRadius);
    borderPath.arcToPoint(
      Offset(left + borderRadius, top),
      radius: Radius.circular(borderRadius),
    );
    borderPath.lineTo(left + borderLength, top);

    // Top-right
    borderPath.moveTo(left + scanAreaSize - borderLength, top);
    borderPath.lineTo(left + scanAreaSize - borderRadius, top);
    borderPath.arcToPoint(
      Offset(left + scanAreaSize, top + borderRadius),
      radius: Radius.circular(borderRadius),
    );
    borderPath.lineTo(left + scanAreaSize, top + borderLength);

    // Bottom-right
    borderPath.moveTo(left + scanAreaSize, top + scanAreaSize - borderLength);
    borderPath.lineTo(left + scanAreaSize, top + scanAreaSize - borderRadius);
    borderPath.arcToPoint(
      Offset(left + scanAreaSize - borderRadius, top + scanAreaSize),
      radius: Radius.circular(borderRadius),
    );
    borderPath.lineTo(left + scanAreaSize - borderLength, top + scanAreaSize);

    // Bottom-left
    borderPath.moveTo(left + borderLength, top + scanAreaSize);
    borderPath.lineTo(left + borderRadius, top + scanAreaSize);
    borderPath.arcToPoint(
      Offset(left, top + scanAreaSize - borderRadius),
      radius: Radius.circular(borderRadius),
    );
    borderPath.lineTo(left, top + scanAreaSize - borderLength);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
