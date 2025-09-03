// lib/src/features/auth/presentation/widgets/debug/token_monitor_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../../../core/storage/simple_token_storage.dart';
import '../../../../../utils/app_logger.dart';
import '../../providers/auth_providers.dart';

/// Debug widget for monitoring token expiry times and auth state
///
/// Features:
/// - Shows access token remaining time
/// - Shows refresh token info
/// - Auto refreshes every second
/// - Shows auth provider state
/// - Manual refresh button
/// - Compact design for home page
class TokenMonitorWidget extends ConsumerStatefulWidget {
  const TokenMonitorWidget({super.key});

  @override
  ConsumerState<TokenMonitorWidget> createState() => _TokenMonitorWidgetState();
}

class _TokenMonitorWidgetState extends ConsumerState<TokenMonitorWidget> {
  Timer? _timer;
  String _accessTokenInfo = 'Loading...';
  String _refreshTokenInfo = 'Loading...';
  bool _hasTokens = false;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _updateTokenInfo();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTokenInfo();
    });
  }

  Future<void> _updateTokenInfo() async {
    try {
      final hasValidTokens = await SimpleTokenStorage.hasValidTokens();
      final expirySeconds = await SimpleTokenStorage.getTokenExpirySeconds();
      final isExpired = await SimpleTokenStorage.isTokenExpired();
      final accessToken = await SimpleTokenStorage.getAccessToken();
      final refreshToken = await SimpleTokenStorage.getRefreshToken();

      if (mounted) {
        setState(() {
          _hasTokens = hasValidTokens;
          _isExpired = isExpired;

          if (expirySeconds != null) {
            if (expirySeconds > 0) {
              final minutes = expirySeconds ~/ 60;
              final seconds = expirySeconds % 60;
              _accessTokenInfo = '${minutes}m ${seconds}s';
            } else {
              _accessTokenInfo = 'EXPIRED';
            }
          } else {
            _accessTokenInfo = 'No expiry info';
          }

          _refreshTokenInfo = refreshToken != null ? 'Available' : 'Missing';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _accessTokenInfo = 'Error: $e';
          _refreshTokenInfo = 'Error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.token, color: _getStatusColor(), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Token Monitor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _updateTokenInfo,
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Token Info
            _buildTokenRow('Access Token:', _accessTokenInfo, _isExpired),
            const SizedBox(height: 4),
            _buildTokenRow('Refresh Token:', _refreshTokenInfo, false),
            const SizedBox(height: 8),

            // Auth State Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getAuthStateColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _getAuthStateColor().withOpacity(0.3),
                ),
              ),
              child: Text(
                'Auth: ${authState.status.name.toUpperCase()}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getAuthStateColor(),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Additional Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Authenticated: ${authState.isAuthenticated ? "YES" : "NO"}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                Text(
                  'Tokens: ${_hasTokens ? "YES" : "NO"}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),

            // Test Buttons (Optional - for testing refresh)
            if (_hasTokens && _isExpired) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _testTokenRefresh,
                  icon: const Icon(Icons.autorenew, size: 16),
                  label: const Text('Test Auto Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTokenRow(String label, String value, bool isError) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isError ? Colors.red[700] : Colors.green[700],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    if (!_hasTokens) return Colors.grey;
    if (_isExpired) return Colors.red;
    return Colors.green;
  }

  Color _getAuthStateColor() {
    final authState = ref.read(authNotifierProvider);
    switch (authState.status) {
      case AuthStatus.authenticated:
        return Colors.green;
      case AuthStatus.unauthenticated:
        return Colors.red;
      case AuthStatus.loading:
        return Colors.orange;
      case AuthStatus.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _testTokenRefresh() async {
    AppLogger.info('🧪 Testing token refresh manually');

    try {
      // Make a test API call that will trigger auth interceptor
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.refreshUserProfile();

      AppLogger.info('✅ Test refresh completed');
    } catch (e) {
      AppLogger.error('❌ Test refresh failed: $e');
    }
  }
}

// Helper enum for AuthStatus if not already defined
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }
