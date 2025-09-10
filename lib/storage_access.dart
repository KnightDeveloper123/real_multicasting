import 'package:permission_handler/permission_handler.dart';

Future<bool> isStorageGranted() async {
  PermissionStatus status = await Permission.storage.status;
  PermissionStatus newStatus = await Permission.manageExternalStorage.status;
  if (status.isGranted || newStatus.isGranted) {
    return true;
  }

  // Request again if denied (but not permanently)
  if (status.isDenied ||
      status.isRestricted ||
      newStatus.isDenied ||
      newStatus.isRestricted) {
    status = await Permission.storage.request();
    status = await Permission.manageExternalStorage.request();
    if (status.isGranted || newStatus.isGranted) {
      return true;
    }
  }

  // If permanently denied, optionally open settings
  if (status.isPermanentlyDenied || newStatus.isPermanentlyDenied) {
    await openAppSettings(); // Suggests manual enable
  }

  return false;
}
