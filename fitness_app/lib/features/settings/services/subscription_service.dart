import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:fitness_app/core/network/api_config.dart';
import 'package:fitness_app/features/auth/services/auth_service.dart';

class SubscriptionResult {
  final bool success;
  final String message;

  const SubscriptionResult({required this.success, required this.message});
}

class SubscriptionService {
  final AuthService _authService = AuthService();

  Future<SubscriptionResult> selectPlan({
    required String planName,
    required bool isPremium,
  }) async {
    final normalizedPlan = planName.trim().toLowerCase();
    final tier = isPremium ? 'premium' : 'basic';

    final payloads = <Map<String, dynamic>>[
      {'plan': normalizedPlan, 'tier': tier},
      {'plan_name': normalizedPlan, 'plan_type': tier},
      {'name': normalizedPlan, 'subscription_type': tier},
    ];

    final urls = <String>[
      ApiConfig.subscriptionSelectUrl,
      ApiConfig.subscriptionsSelectUrl,
      ApiConfig.subscriptionPlanUrl,
      ApiConfig.subscriptionsPlanUrl,
      ApiConfig.subscriptionUrl,
      ApiConfig.subscriptionsUrl,
    ];

    final token = await _authService.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer $token',
    };

    String lastError = 'Unable to connect to server';

    for (final url in urls) {
      for (final body in payloads) {
        try {
          if (kDebugMode) {
            debugPrint('SUBSCRIPTION REQUEST -> $url');
            debugPrint('SUBSCRIPTION BODY -> $body');
          }

          final response = await http
              .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 20));

          Map<String, dynamic> decoded = <String, dynamic>{};
          try {
            final parsed = jsonDecode(response.body);
            if (parsed is Map<String, dynamic>) decoded = parsed;
          } catch (_) {}

          if (kDebugMode) {
            debugPrint('SUBSCRIPTION STATUS -> ${response.statusCode}');
            debugPrint('SUBSCRIPTION RESPONSE -> ${response.body}');
          }

          if (response.statusCode >= 200 && response.statusCode < 300) {
            return SubscriptionResult(
              success: true,
              message: _extractMessage(decoded) ?? 'Plan updated successfully',
            );
          }

          if (response.statusCode == 405) {
            // Endpoint exists but HTTP method is not accepted by backend.
            final allowHeader = response.headers['allow'];
            lastError = allowHeader == null || allowHeader.trim().isEmpty
                ? 'Plan endpoint exists but method is not allowed (405)'
                : 'Plan endpoint exists, allowed methods: $allowHeader';
            continue;
          }

          if (response.statusCode == 404) {
            lastError = 'Endpoint not found (${response.statusCode})';
            break;
          }

          lastError =
              _extractMessage(decoded) ??
              'Failed to update plan (${response.statusCode})';
        } catch (e) {
          lastError = 'Unable to connect to server';
        }
      }
    }

    // Some backends expose /subscription as GET only and accept query params.
    final queryUrls = <String>[
      ApiConfig.subscriptionUrl,
      ApiConfig.subscriptionsUrl,
    ];
    for (final url in queryUrls) {
      try {
        final uri = Uri.parse(url).replace(
          queryParameters: <String, String>{
            'plan': normalizedPlan,
            'tier': tier,
          },
        );
        final response = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 20));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          Map<String, dynamic> decoded = <String, dynamic>{};
          try {
            final parsed = jsonDecode(response.body);
            if (parsed is Map<String, dynamic>) decoded = parsed;
          } catch (_) {}
          return SubscriptionResult(
            success: true,
            message: _extractMessage(decoded) ?? 'Plan request processed',
          );
        }
      } catch (_) {}
    }

    return SubscriptionResult(success: false, message: lastError);
  }

  String? _extractMessage(Map<String, dynamic> data) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) return message;

    final errors = data['errors'];
    if (errors is Map<String, dynamic> && errors.isNotEmpty) {
      final firstError = errors.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        final value = firstError.first;
        if (value is String && value.trim().isNotEmpty) return value;
      }
    }
    return null;
  }
}
