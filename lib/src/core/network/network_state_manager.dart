// lib/src/core/network/network_state_manager.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network state management for production
class NetworkStateManager {
  static final Connectivity _connectivity = Connectivity();

  /// Check if device has internet connection
  static Future<bool> hasInternetConnection() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      // Eğer hiçbiri 'none' değilse, bağlantı var demektir
      return connectivityResults.any(
        (result) => result != ConnectivityResult.none,
      );
    } catch (e) {
      return false;
    }
  }

  /// Enhanced error categorization for production
  static NetworkErrorType categorizeError(String error) {
    final lowerError = error.toLowerCase();

    // Infrastructure errors (ngrok, cloudflare, etc.)
    if (lowerError.contains('html') ||
        lowerError.contains('nginx') ||
        lowerError.contains('cloudflare') ||
        error.length > 500) {
      return NetworkErrorType.infrastructure;
    }

    // Connection errors
    if (lowerError.contains('connection') ||
        lowerError.contains('network') ||
        lowerError.contains('timeout')) {
      return NetworkErrorType.connection;
    }

    // Server errors
    if (lowerError.contains('server') ||
        lowerError.contains('internal') ||
        lowerError.contains('500') ||
        lowerError.contains('502') ||
        lowerError.contains('503')) {
      return NetworkErrorType.server;
    }

    // Auth errors
    if (lowerError.contains('unauthorized') ||
        lowerError.contains('forbidden') ||
        lowerError.contains('401') ||
        lowerError.contains('403')) {
      return NetworkErrorType.auth;
    }

    return NetworkErrorType.unknown;
  }

  /// Get user action recommendations
  static List<String> getErrorActions(NetworkErrorType errorType) {
    switch (errorType) {
      case NetworkErrorType.infrastructure:
        return [
          'Birkaç dakika bekleyin',
          'Uygulamayı yeniden başlatın',
          'Farklı ağ deneyiр',
        ];
      case NetworkErrorType.connection:
        return [
          'İnternet bağlantınızı kontrol edin',
          'WiFi/mobil veriyi açın',
          'Farklı ağa bağlanın',
        ];
      case NetworkErrorType.server:
        return [
          'Birkaç dakika bekleyin',
          'Uygulamayı güncelleyin',
          'Destek ekibiyle iletişime geçin',
        ];
      case NetworkErrorType.auth:
        return [
          'Çıkış yapıp tekrar giriş yapın',
          'Şifrenizi kontrol edin',
          'Hesap durumunuzu kontrol edin',
        ];
      case NetworkErrorType.unknown:
        return [
          'Uygulamayı yeniden başlatın',
          'Cihazınızı yeniden başlatın',
          'Daha sonra tekrar deneyin',
        ];
    }
  }
}

enum NetworkErrorType {
  infrastructure, // ngrok, cloudflare, nginx errors
  connection, // network connectivity issues
  server, // API server errors
  auth, // authentication/authorization errors
  unknown, // other errors
}

/// Provider for network state
final networkStateProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Provider for current connectivity status
final currentConnectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    return results.any((result) => result != ConnectivityResult.none);
  });
});

/// Provider for network status
final hasInternetProvider = FutureProvider<bool>((ref) {
  return NetworkStateManager.hasInternetConnection();
});
