import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const AppFotosGeo());
}

class AppFotosGeo extends StatelessWidget {
  const AppFotosGeo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Fotos + Geolocalização',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const HomePage(title: 'Fotos & Localização'),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _loadSavedImages();
  }

  // Carrega imagens salvas localmente
  Future<void> _loadSavedImages() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${dir.path}/images');
      if (!await imagesDir.exists()) return;

      final files = imagesDir.listSync().whereType<File>().toList()
        ..sort((a, b) => b.path.compareTo(a.path));

      setState(() {
        _images
          ..clear()
          ..addAll(files);
      });
    } catch (_) {}
  }

  Future<bool> _requestPermissions({
    bool forCamera = false,
    bool forLocation = false,
  }) async {
    final perms = <Permission>[];

    if (forCamera) {
      perms.add(Permission.camera);
      perms.add(Permission.photos);
    }
    if (forLocation) {
      perms.add(Permission.locationWhenInUse);
    }

    if (perms.isEmpty) return true;

    final statuses = await perms.request();
    bool ok = true;

    for (final p in perms) {
      final st = statuses[p];
      if (st == null || (!st.isGranted && !st.isLimited)) ok = false;
    }

    return ok;
  }

  Future<File?> _saveXFileToAppDir(XFile xfile) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${dir.path}/images');

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = xfile.path.split('.').last;
      final dest = File('${imagesDir.path}/IMG_$timestamp.$ext');

      return await File(xfile.path).copy(dest.path);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _loading = true);

    final ok = await _requestPermissions(forCamera: false);
    if (!ok) {
      _showSnack('Permissão de galeria negada.');
      setState(() => _loading = false);
      return;
    }

    try {
      final XFile? xfile = await _picker.pickImage(source: ImageSource.gallery);
      if (xfile == null) return;

      final saved = await _saveXFileToAppDir(xfile);
      if (saved != null) {
        setState(() => _images.insert(0, saved));
        _showSnack('Imagem adicionada da galeria.');
      } else {
        _showSnack('Falha ao salvar imagem.');
      }
    } catch (e) {
      _showSnack('Erro ao abrir galeria: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _capturePhoto() async {
    setState(() => _loading = true);

    final ok = await _requestPermissions(forCamera: true);
    if (!ok) {
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

      final saved = await _saveXFileToAppDir(xfile);
      if (saved != null) {
        setState(() => _images.insert(0, saved));
        _showSnack('Foto capturada e salva.');
      } else {
        _showSnack('Falha ao salvar foto.');
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
        _locationText =
            'Localização: ${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
      });
      _showSnack('Localização obtida.');
    } catch (e) {
      _showSnack('Erro ao obter localização: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _removeImage(int index) async {
    final file = _images[index];
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
    setState(() => _images.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
            // Botões
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Capturar foto'),
                      onPressed: _loading ? null : _capturePhoto,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Escolher da galeria'),
                      onPressed: _loading ? null : _pickFromGallery,
                    ),
                  ),
                ],
              ),
            ),

            // Localização
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(_locationText)),
                  if (_loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),

            const Divider(),

            // Lista de imagens
            Expanded(
              child: _images.isEmpty
                  ? const Center(
                      child: Text('Nenhuma imagem.'),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (_, index) {
                        final f = _images[index];

                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              GestureDetector(
                                onLongPress: () async {
                                  final confirm =
                                      await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text(
                                          'Remover imagem?'),
                                      content: const Text(
                                          'Deseja excluir permanentemente?'),
                                      actions: [
                                        TextButton(
                                          child:
                                              const Text('Cancelar'),
                                          onPressed: () =>
                                              Navigator.pop(
                                                  context, false),
                                        ),
                                        TextButton(
                                          child:
                                              const Text('Excluir'),
                                          onPressed: () =>
                                              Navigator.pop(
                                                  context, true),
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
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          FullImagePage(file: f),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  child: Image.file(
                                    f,
                                    width: 140,
                                    height: 140,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 140,
                                child: Text(
                                  f.path.split('/').last,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullImagePage extends StatelessWidget {
  final File file;
  const FullImagePage({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Visualizar imagem')),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(file),
        ),
      ),
    );
  }
}
