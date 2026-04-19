import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/vision/pcd_controller.dart';

class PcdEditorView extends StatefulWidget {
  final String? imagePath;

  const PcdEditorView({super.key, this.imagePath});

  @override
  State<PcdEditorView> createState() => _PcdEditorViewState();
}

class _PcdEditorViewState extends State<PcdEditorView> {
  late final PcdController _controller;

  bool get _isArithmeticOperation =>
      _controller.selectedOperation == 'Operasi Tambah' ||
      _controller.selectedOperation == 'Operasi Kurang';

  @override
  void initState() {
    super.initState();
    _controller = PcdController();
    if (widget.imagePath != null) {
      _controller.loadImageFromPath(widget.imagePath!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FA),
      appBar: AppBar(
        title: const Text("ETS PENGOLHAN CITRA DIGITAL"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF14213D),
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          final double bottomInset = MediaQuery.of(context).padding.bottom;

          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildImageCard(
                          title: 'Gambar Original',
                          accent: const Color(0xFF4F46E5),
                          child: _controller.originalImage != null
                              ? Image.file(
                                  _controller.originalImage!,
                                  fit: BoxFit.cover,
                                )
                              : _buildEmptyState(
                                  icon: Icons.image_not_supported,
                                  message: 'Belum ada gambar',
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildImageCard(
                          title: 'Hasil Proses',
                          accent: const Color(0xFF0EA5E9),
                          trailing: _controller.isProcessing
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : null,
                          child: _controller.processedImage != null
                              ? Image.memory(
                                  _controller.processedImage!,
                                  fit: BoxFit.cover,
                                )
                              : _buildEmptyState(
                                  icon: Icons.tune,
                                  message: 'Belum ada hasil',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _buildControlPanel(),

                const SizedBox(height: 12),

                Padding(
                  padding: EdgeInsets.only(bottom: bottomInset + 12),
                  child: FilledButton.icon(
                    onPressed: _controller.originalImage != null
                        ? _controller.applySelectedFilter
                        : null,
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('Terapkan Filter'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E2F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mode Pengolahan',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _controller.selectedOperation,
            menuMaxHeight: 240,
            elevation: 8,
            borderRadius: BorderRadius.circular(14),
            dropdownColor: Colors.white,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF7FAFF),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              prefixIcon: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD1DBEA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD1DBEA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.6,
                ),
              ),
            ),
            onChanged: _controller.originalImage != null
                ? (String? newValue) {
                    if (newValue != null) {
                      _controller.setOperation(newValue);
                    }
                  }
                : null,
            items: _controller.operations.map<DropdownMenuItem<String>>((
              String value,
            ) {
              return DropdownMenuItem<String>(
                value: value,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _iconForOperation(value),
                      size: 18,
                      color: const Color(0xFF334155),
                    ),
                    const SizedBox(width: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(value, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (_isArithmeticOperation) ...[
            const SizedBox(height: 10),
            Text(
              _controller.selectedOperation == 'Operasi Tambah'
                  ? 'Intensitas Tambah: +${_controller.arithmeticIntensity.round()}'
                  : 'Intensitas Kurang: -${_controller.arithmeticIntensity.round()}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFFB45309),
              ),
            ),
            Slider(
              value: _controller.arithmeticIntensity,
              min: 0,
              max: 100,
              divisions: 100,
              label: _controller.arithmeticIntensity.round().toString(),
              onChanged: _controller.originalImage != null
                  ? _controller.setArithmeticIntensity
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageCard({
    required String title,
    required Color accent,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E2F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: SizedBox.expand(child: child),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForOperation(String operation) {
    if (operation.contains('Morfologi')) return Icons.grid_on_rounded;
    if (operation.contains('Threshold')) return Icons.contrast_rounded;
    if (operation.contains('Edge') || operation.contains('Sobel')) {
      return Icons.filter_center_focus_rounded;
    }
    if (operation.contains('Blur') || operation.contains('Median')) {
      return Icons.blur_on_rounded;
    }
    if (operation.contains('Sharpening')) return Icons.auto_fix_high_rounded;
    if (operation.contains('Histogram')) return Icons.bar_chart_rounded;
    if (operation.contains('Tambah') || operation.contains('Kurang')) {
      return Icons.exposure_rounded;
    }
    if (operation.contains('Boolean')) return Icons.flip_rounded;
    if (operation.contains('Grayscale')) return Icons.monochrome_photos_rounded;
    return Icons.tune_rounded;
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
