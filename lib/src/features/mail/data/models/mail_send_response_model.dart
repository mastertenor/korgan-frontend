// lib/src/features/mail/data/models/mail_send_response_model.dart

import '../../domain/entities/compose_result.dart';

/// Data model for mail send API response
///
/// This model parses the JSON response from the /api/sendmailrequest endpoint
/// and converts it to domain entities.
class MailSendResponseModel {
  final bool success;
  final String? message;
  final String? requestId;
  final int? queuePosition;
  final String? estimatedProcessingTime;
  final String? error;
  final String? code;
  final int? processingTimeMs;

  const MailSendResponseModel({
    required this.success,
    this.message,
    this.requestId,
    this.queuePosition,
    this.estimatedProcessingTime,
    this.error,
    this.code,
    this.processingTimeMs,
  });

  /// Create from API JSON response
  factory MailSendResponseModel.fromJson(Map<String, dynamic> json) {
    return MailSendResponseModel(
      success: json['success'] == true,
      message: json['message']?.toString(),
      requestId: json['request_id']?.toString(),
      queuePosition: json['queue_position'] as int?,
      estimatedProcessingTime: json['estimated_processing_time']?.toString(),
      error: json['error']?.toString(),
      code: json['code']?.toString(),
      processingTimeMs: json['processing_time_ms'] as int?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{
      'success': success,
    };

    if (message != null) result['message'] = message;
    if (requestId != null) result['request_id'] = requestId;
    if (queuePosition != null) result['queue_position'] = queuePosition;
    if (estimatedProcessingTime != null) {
      result['estimated_processing_time'] = estimatedProcessingTime;
    }
    if (error != null) result['error'] = error;
    if (code != null) result['code'] = code;
    if (processingTimeMs != null) result['processing_time_ms'] = processingTimeMs;

    return result;
  }

  /// Convert to domain entity
  ComposeResult toDomain() {
    if (success) {
      return ComposeResult.success(
        message: message ?? 'Email queued successfully',
        requestId: requestId ?? '',
        queuePosition: queuePosition ?? 0,
        estimatedProcessingTime: estimatedProcessingTime ?? '',
        processingTimeMs: processingTimeMs,
      );
    } else {
      return ComposeResult.failure(
        error: error ?? 'Unknown error',
        code: code ?? 'UNKNOWN_ERROR',
        processingTimeMs: processingTimeMs,
      );
    }
  }

  /// Create successful response model
  factory MailSendResponseModel.success({
    required String message,
    required String requestId,
    required int queuePosition,
    required String estimatedProcessingTime,
    int? processingTimeMs,
  }) {
    return MailSendResponseModel(
      success: true,
      message: message,
      requestId: requestId,
      queuePosition: queuePosition,
      estimatedProcessingTime: estimatedProcessingTime,
      processingTimeMs: processingTimeMs,
    );
  }

  /// Create failure response model
  factory MailSendResponseModel.failure({
    required String error,
    required String code,
    int? processingTimeMs,
  }) {
    return MailSendResponseModel(
      success: false,
      error: error,
      code: code,
      processingTimeMs: processingTimeMs,
    );
  }

  /// Check if response indicates success
  bool get isSuccess => success;

  /// Check if response indicates failure
  bool get isFailure => !success;

  /// Get user-friendly status message
  String get statusMessage {
    if (success) {
      return message ?? 'Email başarıyla gönderildi!';
    } else {
      return error ?? 'Email gönderilemedi';
    }
  }

  /// Get debug information
  String get debugInfo {
    final buffer = StringBuffer();
    buffer.writeln('MailSendResponseModel:');
    buffer.writeln('  Success: $success');
    
    if (success) {
      buffer.writeln('  Message: $message');
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
    return other is MailSendResponseModel &&
           other.success == success &&
           other.requestId == requestId &&
           other.error == error &&
           other.code == code;
  }

  @override
  int get hashCode => Object.hash(success, requestId, error, code);

  @override
  String toString() {
    return success 
        ? 'MailSendResponseModel.success(requestId: $requestId, queue: $queuePosition)'
        : 'MailSendResponseModel.failure(error: $error, code: $code)';
  }
}