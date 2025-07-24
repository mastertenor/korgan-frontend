// lib/src/features/mail/domain/entities/compose_result.dart

/// Compose result entity for mail send operations
///
/// Represents the result of a mail send request from the API.
/// Handles both successful and failed responses from /api/sendmailrequest.
class ComposeResult {
  /// Whether the request was successful
  final bool success;

  /// Main message from the API
  final String message;

  // ========== SUCCESS FIELDS ==========

  /// Unique request ID for tracking (success only)
  final String? requestId;

  /// Position in processing queue (success only)
  final int? queuePosition;

  /// Estimated time for processing (success only)
  final String? estimatedProcessingTime;

  // ========== ERROR FIELDS ==========

  /// Error message (failure only)
  final String? error;

  /// Error code (failure only)
  final String? code;

  // ========== COMMON FIELDS ==========

  /// Processing time in milliseconds
  final int? processingTimeMs;

  const ComposeResult({
    required this.success,
    required this.message,
    this.requestId,
    this.queuePosition,
    this.estimatedProcessingTime,
    this.error,
    this.code,
    this.processingTimeMs,
  });

  /// Create successful result
  factory ComposeResult.success({
    required String message,
    required String requestId,
    required int queuePosition,
    required String estimatedProcessingTime,
    int? processingTimeMs,
  }) {
    return ComposeResult(
      success: true,
      message: message,
      requestId: requestId,
      queuePosition: queuePosition,
      estimatedProcessingTime: estimatedProcessingTime,
      processingTimeMs: processingTimeMs,
    );
  }

  /// Create failure result
  factory ComposeResult.failure({
    required String error,
    required String code,
    int? processingTimeMs,
  }) {
    return ComposeResult(
      success: false,
      message: error,
      error: error,
      code: code,
      processingTimeMs: processingTimeMs,
    );
  }

  /// Create from API JSON response
  factory ComposeResult.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true;

    if (success) {
      return ComposeResult.success(
        message: json['message']?.toString() ?? 'Email queued successfully',
        requestId: json['request_id']?.toString() ?? '',
        queuePosition: json['queue_position'] as int? ?? 0,
        estimatedProcessingTime: json['estimated_processing_time']?.toString() ?? '',
        processingTimeMs: json['processing_time_ms'] as int?,
      );
    } else {
      return ComposeResult.failure(
        error: json['error']?.toString() ?? 'Unknown error',
        code: json['code']?.toString() ?? 'UNKNOWN_ERROR',
        processingTimeMs: json['processing_time_ms'] as int?,
      );
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{
      'success': success,
      'message': message,
    };

    if (success) {
      if (requestId != null) result['request_id'] = requestId;
      if (queuePosition != null) result['queue_position'] = queuePosition;
      if (estimatedProcessingTime != null) {
        result['estimated_processing_time'] = estimatedProcessingTime;
      }
    } else {
      if (error != null) result['error'] = error;
      if (code != null) result['code'] = code;
    }

    if (processingTimeMs != null) {
      result['processing_time_ms'] = processingTimeMs;
    }

    return result;
  }

  /// Get user-friendly status message
  String get statusMessage {
    if (success) {
      return 'Email başarıyla gönderildi! Kuyruktaki sıra: ${queuePosition ?? 0}';
    } else {
      return 'Email gönderilemedi: ${error ?? 'Bilinmeyen hata'}';
    }
  }

  /// Get detailed info for debugging
  String get debugInfo {
    final buffer = StringBuffer();
    buffer.writeln('ComposeResult:');
    buffer.writeln('  Success: $success');
    buffer.writeln('  Message: $message');
    
    if (success) {
      buffer.writeln('  Request ID: $requestId');
      buffer.writeln('  Queue Position: $queuePosition');
      buffer.writeln('  Estimated Time: $estimatedProcessingTime');
    } else {
      buffer.writeln('  Error: $error');
      buffer.writeln('  Code: $code');
    }
    
    if (processingTimeMs != null) {
      buffer.writeln('  Processing Time: ${processingTimeMs}ms');
    }
    
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ComposeResult &&
           other.success == success &&
           other.message == message &&
           other.requestId == requestId &&
           other.error == error &&
           other.code == code;
  }

  @override
  int get hashCode => Object.hash(success, message, requestId, error, code);

  @override
  String toString() {
    return success 
        ? 'ComposeResult.success(requestId: $requestId, queue: $queuePosition)'
        : 'ComposeResult.failure(error: $error, code: $code)';
  }
}