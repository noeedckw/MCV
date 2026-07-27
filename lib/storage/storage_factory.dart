import 'local_storage_service.dart';
import 'local_storage_native.dart'
    if (dart.library.html) 'local_storage_web.dart';

LocalStorageService createStorageService() => LocalStorageServiceImpl();
