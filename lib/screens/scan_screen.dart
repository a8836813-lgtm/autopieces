import 'dart:io';

import 'package:camera/camera.dart';
import 'package:material_ui/material_ui.dart';

import '../data/scan_mode.dart';
import '../services/part_scanner.dart';
import '../services/part_scanner_factory.dart';
import '../theme.dart';
import 'candidates_screen.dart';

/// Multi-photo scan: the user takes several photos of a part from different
/// angles, then the scanner compares them with the catalog.
class ScanScreen extends StatefulWidget {
  final ScanMode mode;

  const ScanScreen({super.key, this.mode = ScanMode.client});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  static const int _maxPhotos = 6;
  static const Color _dark = Color(0xFF14181F);
  static const Color _panel = Color(0xFF2A303B);
  static const Color _lightText = Color(0xFFD5D9E0);

  final PartScanner _scanner = PartScannerFactory.create();
  final List<String> _photos = [];
  CameraController? _controller;
  String? _cameraMessage;
  bool _identifying = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraMessage =
                'No camera found on this device. Use the button below to add demo photos.';
          });
        }
        return;
      }
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraMessage =
              'The camera is not available. Use the button below to add demo photos.';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_photos.length >= _maxPhotos) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      // Demo mode when there is no camera (emulator, desktop).
      setState(() => _photos.add('demo'));
      return;
    }
    try {
      final file = await controller.takePicture();
      if (mounted) setState(() => _photos.add(file.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not take the photo. Try again.')),
        );
      }
    }
  }

  Future<void> _identify() async {
    if (_photos.isEmpty || _identifying) return;
    setState(() => _identifying = true);
    try {
      final candidates = await _scanner.identify(List<String>.of(_photos));
      if (!mounted) return;
      setState(() => _identifying = false);
      if (candidates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No matching part in the catalog. Try a clearer photo or search by name.')),
        );
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CandidatesScreen(
            candidates: candidates,
            mode: widget.mode,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _identifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not identify the part. Try again.')),
      );
    }
  }

  Widget _preview() {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      return Center(child: CameraPreview(controller));
    }
    return Container(
      color: const Color(0xFF1B2029),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Text(
        _cameraMessage ?? 'Starting the camera…',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
      ),
    );
  }

  Widget _thumb(int index) {
    final path = _photos[index];
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 60,
              height: 60,
              child: path == 'demo'
                  ? Container(
                      color: _panel,
                      child: const Icon(
                        Icons.album_outlined,
                        color: Color(0xFF8A93A3),
                      ),
                    )
                  : Image.file(File(path), fit: BoxFit.cover),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Tooltip(
              message: 'Remove photo',
              child: InkWell(
                onTap: () => setState(() => _photos.removeAt(index)),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isShop = widget.mode == ScanMode.shop;
    return Scaffold(
      backgroundColor: _dark,
      appBar: AppBar(
        backgroundColor: _dark,
        foregroundColor: Colors.white,
        title: Text(
          isShop ? 'Scan a part from your shelf' : 'Scan a part',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                '${_photos.length} of $_maxPhotos photos · take 3 or more from different angles and include any printed number',
                style: const TextStyle(color: _lightText, fontSize: 14),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox.expand(child: _preview()),
                ),
              ),
            ),
            SizedBox(
              height: 76,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                children: [
                  for (var i = 0; i < _photos.length; i++) _thumb(i),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Semantics(
                button: true,
                label: 'Take photo',
                child: GestureDetector(
                  onTap: _capture,
                  child: Container(
                    width: 68,
                    height: 68,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed:
                      (_photos.isEmpty || _identifying) ? null : _identify,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _identifying ? 'Comparing photos…' : 'Identify part',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
