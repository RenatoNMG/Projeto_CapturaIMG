import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

import 'image_page.dart';
import '../utils/manager.dart';
import '../utils/permissicoes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];
  bool _loading = false;
  String _locationText = 'Localização: ---';

  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _loadSavedImages();
  }

  Future<void> _loadSavedImages() async {
    final files = await loadImagesFromStorage();
    setState(() {
      _images
        ..clear()
        ..addAll(files);
    });
  }

  Future<void> _pickFromGallery() async {
    setState(() => _loading = true);

    if (!await requestGalleryPermission()) {
      _showSnack('Permissão de galeria negada.');
      setState(() => _loading = false);
      return;
    }

    try {
      final XFile? xfile = await _picker.pickImage(source: ImageSource.gallery);
      if (xfile == null) return;

      final saved = await saveXFile(xfile);
      if (saved != null) {
        setState(() => _images.insert(0, saved));
        _showSnack('Imagem adicionada da galeria.');
      }
    } catch (e) {
      _showSnack('Erro ao abrir galeria: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _capturePhoto() async {
    setState(() => _loading = true);

    if (!await requestCameraPermission()) {
      _showSnack('Permissão de câmera negada.');
      setState(() => _loading = false);
      return;
    }

    try {
      final XFile? xfile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );
      if (xfile == null) return;

      final saved = await saveXFile(xfile);
      if (saved != null) {
        setState(() => _images.insert(0, saved));
        _showSnack('Foto capturada.');
      }
    } catch (e) {
      _showSnack('Erro ao capturar foto: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _getLocation() async {
    setState(() => _loading = true);

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnack('Permissão de localização negada.');
        setState(() => _loading = false);
        return;
      }
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locationText =
            'Localização: ${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
      });
    } catch (e) {
      _showSnack('Erro ao obter localização: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _removeImage(int index) async {
    final file = _images[index];
    await deleteImage(file);
    setState(() => _images.removeAt(index));
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF0C1D34);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),

      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shadowColor: Colors.black45,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getLocation,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSavedImages,
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            /// Botões
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _styledButton(
                      icon: Icons.camera_alt,
                      text: "Capturar foto",
                      onTap: _loading ? null : _capturePhoto,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _styledButton(
                      icon: Icons.photo_library,
                      text: "Galeria",
                      onTap: _loading ? null : _pickFromGallery,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// Localização
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 6,
                      color: Colors.black12,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _locationText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_loading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// MAPA - aparece somente quando tiver localização
            if (_lat != null && _lng != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 6,
                        color: Colors.black12,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(_lat!, _lng!),
                        initialZoom: 16,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.myapp',
                        ),

                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(_lat!, _lng!),
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            /// Lista de imagens
            Expanded(
              child: _images.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma imagem.',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  : _buildImageList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Botão estilizado
  Widget _styledButton({
    required IconData icon,
    required String text,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 4,
        shadowColor: color.withOpacity(0.4),
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Lista horizontal de imagens
  Widget _buildImageList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _images.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (_, index) {
        final f = _images[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GestureDetector(
            onLongPress: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Remover imagem?'),
                  content: const Text('Deseja excluir permanentemente?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancelar'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    TextButton(
                      child: const Text('Excluir'),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _removeImage(index);
              }
            },
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FullImagePage(file: f)),
              );
            },
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 7,
                        color: Colors.black26,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      f,
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 150,
                  child: Text(
                    f.path.split('/').last,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
