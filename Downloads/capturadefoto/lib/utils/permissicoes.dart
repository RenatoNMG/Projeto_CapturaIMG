import 'package:permission_handler/permission_handler.dart';

Future<bool> requestCameraPermission() async {
  final perms = [Permission.camera, Permission.photos];
  final result = await perms.request();

  return result.values.every((st) => st.isGranted || st.isLimited);
}

Future<bool> requestGalleryPermission() async {
  final perms = [Permission.photos];
  final result = await perms.request();

  return result.values.every((st) => st.isGranted || st.isLimited);
}
