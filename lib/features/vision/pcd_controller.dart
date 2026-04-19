import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class PcdController extends ChangeNotifier {
  File? originalImage;
  Uint8List? processedImage;
  bool isProcessing = false;
  double arithmeticIntensity = 50;

  // State untuk Dropdown
  String selectedOperation = 'Grayscale';

  // Daftar Operasi untuk Dropdown Menu
  final List<String> operations = [
    'Grayscale',
    'Operasi Tambah',
    'Operasi Kurang',
    'Mean Filter (Blur)',
    'Median Filter',
    'Gaussian Blur',
    'Sharpening (Penajaman)',
    'Edge Detection (Canny)',
    'Sobel Edge Detection',
    'Histogram Equalization',
    'Thresholding (Otsu)',
    'Adaptive Threshold',
    'Morfologi: Dilasi',
    'Morfologi: Erosi',
    'Morfologi: Opening',
    'Morfologi: Closing',
    'Morfologi: Boundary',
    'Boolean (Invert/NOT)',
  ];

  void loadImageFromPath(String path) {
    originalImage = File(path);
    processedImage = null;
    notifyListeners();
  }

  void setOperation(String operation) {
    selectedOperation = operation;
    notifyListeners();
    // Otomatis terapkan filter saat dropdown diubah
    if (originalImage != null) {
      applySelectedFilter();
    }
  }

  void setArithmeticIntensity(double value) {
    arithmeticIntensity = value;
    notifyListeners();
    if (originalImage != null &&
        (selectedOperation == 'Operasi Tambah' ||
            selectedOperation == 'Operasi Kurang')) {
      applySelectedFilter();
    }
  }

  // --- FUNGSI UTAMA PENGOLAHAN CITRA ---
  Future<void> applySelectedFilter() async {
    if (originalImage == null) return;

    isProcessing = true;
    notifyListeners();

    try {
      cv.Mat src = cv.imread(originalImage!.path);
      cv.Mat dst;
      final kernel3x3 = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));

      // Switch Case untuk setiap operasi dari Dropdown
      switch (selectedOperation) {
        case 'Grayscale':
          dst = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
          break;

        case 'Operasi Tambah':
          dst = cv.convertScaleAbs(src, alpha: 1.0, beta: arithmeticIntensity);
          break;

        case 'Operasi Kurang':
          dst = cv.convertScaleAbs(src, alpha: 1.0, beta: -arithmeticIntensity);
          break;

        case 'Mean Filter (Blur)':
          dst = cv.blur(src, (15, 15));
          break;

        case 'Median Filter':
          dst = cv.medianBlur(src, 15);
          break;

        case 'Gaussian Blur':
          dst = cv.gaussianBlur(src, (15, 15), 0);
          break;

        case 'Edge Detection (Canny)':
          cv.Mat gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
          dst = cv.canny(gray, 100, 200);
          break;

        case 'Histogram Equalization':
          cv.Mat gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
          dst = cv.equalizeHist(gray);
          break;

        case 'Thresholding (Otsu)':
          cv.Mat gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
          dst = cv.threshold(gray, 0, 255, 0 | 8).$2;
          break;

        case 'Adaptive Threshold':
          cv.Mat gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
          dst = cv.adaptiveThreshold(gray, 255, 1, 0, 11, 2);
          break;

        case 'Boolean (Invert/NOT)':
          dst = cv.convertScaleAbs(src, alpha: -1.0, beta: 255.0);
          break;

        case 'Sharpening (Penajaman)':
          final sharpKernel = cv.Mat.fromList(3, 3, cv.MatType.CV_32FC1, [
            0.0,
            -1.0,
            0.0,
            -1.0,
            5.0,
            -1.0,
            0.0,
            -1.0,
            0.0,
          ]);

          dst = cv.filter2D(src, src.type.value, sharpKernel);
          break;
        case 'Sobel Edge Detection':
          cv.Mat gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
          cv.Mat gradX = cv.sobel(gray, cv.MatType.CV_16S, 1, 0);
          cv.Mat gradY = cv.sobel(gray, cv.MatType.CV_16S, 0, 1);
          cv.Mat absX = cv.convertScaleAbs(gradX);
          cv.Mat absY = cv.convertScaleAbs(gradY);
          dst = cv.addWeighted(absX, 0.5, absY, 0.5, 0);
          break;
        case 'Morfologi: Dilasi':
          // Pipeline morfologi: grayscale -> threshold Otsu -> dilasi
          cv.Mat gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
          cv.Mat binary = cv.threshold(gray, 0, 255, 0 | 8).$2;
          // Menebalkan bagian putih (objek)
          dst = cv.dilate(binary, kernel3x3);
          break;

        case 'Morfologi: Erosi':
          cv.Mat gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
          cv.Mat binary = cv.threshold(gray, 0, 255, 0 | 8).$2;
          dst = cv.erode(binary, kernel3x3);
          break;

        case 'Morfologi: Opening':
          cv.Mat gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
          cv.Mat binary = cv.threshold(gray, 0, 255, 0 | 8).$2;
          dst = cv.morphologyEx(binary, cv.MORPH_OPEN, kernel3x3);
          break;

        case 'Morfologi: Closing':
          cv.Mat gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
          cv.Mat binary = cv.threshold(gray, 0, 255, 0 | 8).$2;
          dst = cv.morphologyEx(binary, cv.MORPH_CLOSE, kernel3x3);
          break;

        case 'Morfologi: Boundary':
          cv.Mat gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
          cv.Mat binary = cv.threshold(gray, 0, 255, 0 | 8).$2;
          dst = cv.morphologyEx(binary, cv.MORPH_GRADIENT, kernel3x3);
          break;

        default:
          dst = src; // Jika tidak ada, kembalikan gambar asli
      }

      final result = cv.imencode(".jpg", dst);
      processedImage = result.$2;
    } catch (e) {
      debugPrint("Error OpenCV pada $selectedOperation: $e");
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }
}
