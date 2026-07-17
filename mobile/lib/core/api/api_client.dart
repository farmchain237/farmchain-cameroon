import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://agrofamily-backend.onrender.com/api/v1',
);

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _apiBaseUrl,
      // Fix 3: increased to 60s so a sleeping Render server has time to wake up
      // before the app gives up and shows an error. Free tier sleeps after
      // 15 min of inactivity — first request of the day always takes ~30-50s.
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = Hive.box('auth').get('token') as String?;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;
  Dio get dio => _dio;
}
