import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? controller;
  bool isInitialized = false;
  bool isFlashOn = false;
  bool hasCameraAccess = true;
  bool isPermissionPermanentlyDenied = false;
  String? errorMessage;

  VisionController() {
    WidgetsBinding.instance.addObserver(this); // Pantau status aplikasi
    initCamera();
  }

  Future<void> toggleFlash() async {
    // Keamanan ekstra: jangan lakukan apa pun jika kamera belum siap
    if (controller == null || !controller!.value.isInitialized) return;

    try {
      if (isFlashOn) {
        await controller!.setFlashMode(FlashMode.off);
        isFlashOn = false;
      } else {
        await controller!.setFlashMode(FlashMode.torch); // Torch menyala terus
        isFlashOn = true;
      }
      notifyListeners(); // Beri tahu UI untuk mengubah ikon tombol
    } catch (e) {
      errorMessage = "Gagal menyalakan senter: $e";
      notifyListeners();
    }
  }
  // Fungsi untuk mengambil foto dari frame kamera saat ini
  Future<XFile?> captureFrame() async {
    if (controller == null || !controller!.value.isInitialized) return null;
    
    try {
      // Pastikan flash menyala jika isFlashOn true, lalu jepret
      final image = await controller!.takePicture();
      return image;
    } catch (e) {
      debugPrint("Gagal mengambil foto: $e");
      return null;
    }
  }

  Future<void> initCamera() async {
    isInitialized = false;
    errorMessage = null;

    try {
      PermissionStatus permissionStatus = await Permission.camera.status;
      if (!permissionStatus.isGranted) {
        permissionStatus = await Permission.camera.request();
      }

      if (!permissionStatus.isGranted) {
        hasCameraAccess = false;
        isPermissionPermanentlyDenied =
            permissionStatus.isPermanentlyDenied ||
            permissionStatus.isRestricted;
        errorMessage = 'No Camera Access';
        notifyListeners();
        return;
      }

      hasCameraAccess = true;
      isPermissionPermanentlyDenied = false;

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        errorMessage = "No camera detected on device.";
        notifyListeners();
        return;
      }

      // Pilih kamera belakang (index 0) dengan resolusi medium
      controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false, // Kita hanya butuh visual
      );

      await controller!.initialize();
      await controller!.setFlashMode(FlashMode.off);
      isInitialized = true;
      isFlashOn = false;
      errorMessage = null;
    } catch (e) {
      if ('$e'.contains('CameraAccessDenied')) {
        hasCameraAccess = false;
        errorMessage = 'No Camera Access';
      } else {
        errorMessage = "Failed to initialize camera: $e";
      }
    }
    notifyListeners();
  }

  Future<void> openDeviceSettings() async {
    await openAppSettings();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
      isInitialized = false;
      isFlashOn = false;
      notifyListeners();
    } else if (state == AppLifecycleState.resumed) {
      initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Hapus observer
    controller?.dispose(); // Matikan sensor
    super.dispose();
  }
}
