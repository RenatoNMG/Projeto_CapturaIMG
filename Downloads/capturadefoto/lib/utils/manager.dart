import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<File?> saveXFile(XFile xfile) async {
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

Future<List<File>> loadImagesFromStorage() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${dir.path}/images');

    if (!await imagesDir.exists()) return [];

    final files = imagesDir.listSync().whereType<File>().toList()
      ..sort((a, b) => b.path.compareTo(a.path));

    return files;
  } catch (_) {
    return [];
  }
}

Future<void> deleteImage(File file) async {
  if (await file.exists()) await file.delete();
}
