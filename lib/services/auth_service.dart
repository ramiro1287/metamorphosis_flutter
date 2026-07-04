import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/environment.dart';

// Equivalente a client/src/services/authService.js
// Usa Dio en lugar de fetch nativo, con interceptor de refresh token automático.

/// Instancia global de Dio con el interceptor de autenticación ya configurado.
final Dio authDio = _buildAuthDio();

Dio _buildAuthDio() {
  final dio = Dio(BaseOptions(
    baseUrl: baseServerUrl,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (DioException error, handler) async {
      // Si recibimos 401, intentamos refrescar el token una vez
      if (error.response?.statusCode == 401) {
        final newToken = await AuthService.refreshAccessToken();
        if (newToken != null) {
          // Reintenta la petición original con el nuevo token
          final opts = error.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          try {
            final response = await authDio.fetch(opts);
            handler.resolve(response);
            return;
          } catch (_) {
            // Si el reintento también falla, propaga el error original
          }
        }
      }
      handler.next(error);
    },
  ));

  return dio;
}

class AuthService {
  // -------------------------------------------------------
  // Token management (equivalente a saveToken / logout de authService.js)
  // -------------------------------------------------------

  static Future<void> saveToken(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // -------------------------------------------------------
  // refreshAccessToken: POST /auth/token/refresh/
  // Equivalente a refreshAccessToken() de authService.js
  // -------------------------------------------------------

  static Future<String?> refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken == null) return null;

    try {
      // Usamos un Dio limpio (sin interceptor) para evitar recursión infinita
      final plainDio = Dio(BaseOptions(baseUrl: baseServerUrl));
      final response = await plainDio.post(
        '/auth/token/refresh/',
        data: {'refresh': refreshToken},
      );

      final access = response.data['access'] as String?;
      final refresh = response.data['refresh'] as String?;

      if (access != null && refresh != null) {
        await saveToken(access, refresh);
        return access;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------
  // Helpers HTTP con autenticación
  // Equivalentes a fetchWithAuth() de authService.js
  // -------------------------------------------------------

  static Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return authDio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  static Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return authDio.post<T>(path, data: data, options: options);
  }

  static Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return authDio.put<T>(path, data: data, options: options);
  }

  static Future<Response<T>> delete<T>(
    String path, {
    Options? options,
  }) {
    return authDio.delete<T>(path, options: options);
  }
}
