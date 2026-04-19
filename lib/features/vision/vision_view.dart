import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logbook_app_001/features/vision/damage_painter.dart';
import 'package:logbook_app_001/features/vision/vision_controller.dart';
import 'package:logbook_app_001/features/vision/pcd_editor_view.dart';
import 'dart:async';
import 'dart:math';

class _MockDetectionData {
  final Offset position;
  final String damageCode;
  final double confidence;

  const _MockDetectionData({
    required this.position,
    required this.damageCode,
    required this.confidence,
  });
}

class VisionView extends StatefulWidget {
  const VisionView({super.key});

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  // Inisialisasi controller secara lokal untuk halaman ini
  late final VisionController _visionController;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isOverlayEnabled = true;

  final ValueNotifier<_MockDetectionData> _mockDetection =
      ValueNotifier<_MockDetectionData>(
        const _MockDetectionData(
          position: Offset(0.5, 0.5),
          damageCode: 'D40',
          confidence: 0.92,
        ),
      );
  Timer? _mockTimer;

  @override
  void initState() {
    super.initState();
    _visionController = VisionController();
    _startMockDetection();
  }

  void _startMockDetection() {
    // Timer mock setiap 3 detik: simulasi posisi + kelas kerusakan
    _mockTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final double randomX = 0.2 + Random().nextDouble() * 0.6;
      final double randomY = 0.2 + Random().nextDouble() * 0.6;
      final bool heavyDamage = Random().nextBool();

      _mockDetection.value = _MockDetectionData(
        position: Offset(randomX, randomY),
        damageCode: heavyDamage ? 'D40' : 'D00',
        confidence: heavyDamage ? 0.92 : 0.85,
      );
    });
  }

  Future<void> _openPcdFromGallery() async {
    final XFile? selectedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (selectedImage != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PcdEditorView(imagePath: selectedImage.path),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    _mockDetection.dispose();
    // WAJIB: Memutus akses kamera saat pindah halaman
    _visionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: _visionController,
        builder: (context, child) {
          if (!_visionController.hasCameraAccess) {
            return _buildNoCameraAccessState();
          }

          if (_visionController.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _visionController.errorMessage!,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Tampilkan loading jika kamera sedang inisialisasi
          if (!_visionController.isInitialized) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blueAccent),
                  SizedBox(height: 16),
                  Text(
                    'Menghubungkan ke Sensor Visual...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return _buildVisionStack();
        },
      ),
    );
  }

  Widget _buildNoCameraAccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography, size: 54, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'No Camera Access',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _visionController.isPermissionPermanentlyDenied
                  ? 'Izin kamera ditolak permanen. Buka Settings untuk mengaktifkan izin kamera.'
                  : 'Aplikasi membutuhkan akses kamera untuk memulai Smart-Patrol Vision.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _visionController.openDeviceSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _visionController.initCamera,
              child: const Text('Retry Camera Access'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisionStack() {
    final CameraController cameraController = _visionController.controller!;
    final double topSafeArea = MediaQuery.of(context).padding.top;
    final double bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        // LAYER 1: Hardware Preview
        ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: cameraController.value.previewSize!.height,
                height: cameraController.value.previewSize!.width,
                child: CameraPreview(cameraController),
              ),
            ),
          ),
        ),

        // LAYER 2: Digital Overlay (Canvas)
        if (_isOverlayEnabled)
          Positioned.fill(
            child: ValueListenableBuilder<_MockDetectionData>(
              valueListenable: _mockDetection,
              builder: (context, detection, child) {
                return CustomPaint(
                  painter: DamagePainter(
                    normalizedX: detection.position.dx,
                    normalizedY: detection.position.dy,
                    damageCode: detection.damageCode,
                    confidence: detection.confidence,
                  ),
                );
              },
            ),
          ),

        // LAYER 3: Top black bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(height: topSafeArea + 72, color: Colors.black87),
        ),

        // LAYER 4: Top soft fade
        Positioned(
          top: topSafeArea + 72,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: 60,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x88000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
        ),

        // LAYER 5: Bottom gradient for controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xCC000000)],
                ),
              ),
            ),
          ),
        ),

        // LAYER 6: Top controls
        Positioned(
          top: topSafeArea + 10,
          left: 10,
          right: 12,
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white24,
                  padding: const EdgeInsets.all(10),
                ),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Smart-Patrol Vision',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Overlay',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch.adaptive(
                      value: _isOverlayEnabled,
                      onChanged: (value) {
                        setState(() {
                          _isOverlayEnabled = value;
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () => _visionController.toggleFlash(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white24,
                        minimumSize: const Size(36, 36),
                        padding: const EdgeInsets.all(6),
                      ),
                      icon: Icon(
                        _visionController.isFlashOn
                            ? Icons.flash_on
                            : Icons.flash_off,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // LAYER 7: Bottom capture controls
        Positioned(
          left: 20,
          right: 20,
          bottom: bottomSafeArea + 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _openPcdFromGallery,
                tooltip: 'Upload dari Galeri',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white24,
                  padding: const EdgeInsets.all(14),
                ),
                icon: const Icon(
                  Icons.photo_library,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              InkWell(
                onTap: () async {
                  final capturedFile = await _visionController.captureFrame();

                  if (capturedFile != null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PcdEditorView(imagePath: capturedFile.path),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 5),
                    color: Colors.white.withOpacity(0.12),
                  ),
                  child: Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 52),
            ],
          ),
        ),

        // LAYER 8: Center guide
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white30, width: 1.2),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
