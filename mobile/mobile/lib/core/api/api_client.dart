import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

/// Base URL swapped per environment via --dart-define=API_BASE_URL=...
const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://agrofamily-backend.onrender.com/api/v1',
);

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: const Duration(seconds: 15), // generous for 2G/3G
      receiveTimeout: const Duration(seconds: 20),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = Hive.box('auth').get('token') as String?;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Network drop on a bad connection — the offline queue (see
        // core/api/offline_queue.dart) retries idempotent requests later
        // instead of surfacing a raw Dio error to the farmer.
        return handler.next(error);
      },
    ));
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  Dio get dio => _dio;
}
