import 'package:permission_handler/permission_handler.dart';


Future<PermissionStatus> checkPermission() async{
  PermissionStatus result = await Permission.location.status;
  return result;
}

Future<PermissionStatus> requestPermissions()async{
  PermissionStatus result = await Permission.location.request();
  return result;
}