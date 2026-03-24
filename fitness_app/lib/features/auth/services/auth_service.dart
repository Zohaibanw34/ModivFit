import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/core/network/api_config.dart';

class AuthResult {
  final bool success;
  final String message;
  final String? token;
  final String? otp;

  const AuthResult({
    required this.success,
    required this.message,
    this.token,
    this.otp,
  });
}

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _emailKey = 'auth_email';
  static const _passwordKey = 'auth_password';
  static const _signupEmailKey = 'signup_email';
  static const _pendingSignupNameKey = 'pending_signup_name';
  static const _pendingSignupEmailKey = 'pending_signup_email';
  static const _pendingSignupPasswordKey = 'pending_signup_password';
  static const _pendingSignupPhoneKey = 'pending_signup_phone';

  // REGISTER
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    Map<String, dynamic>? onboardingData,
  }) async {
    final body = {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      if (phone != null && phone.trim().isNotEmpty) 'number': phone.trim(),
      if (onboardingData != null) ...onboardingData,
    };

    final result = await _authenticateCandidates(
      urls: [ApiConfig.authSignupUrl],
      body: body,
    );
    if (result.success) {
      await saveSignupEmail(email.trim());
    }
    return result;
  }

  // LOGIN
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final body = {'email': email.trim(), 'password': password};

    return _authenticateCandidates(
      urls: [ApiConfig.authLoginUrl, ApiConfig.authSigninUrl],
      body: body,
    );
  }

  // FORGOT PASSWORD (SEND OTP)
  Future<AuthResult> forgotPassword({required String email}) async {
    final normalizedEmail = email.trim();

    return _authenticateCandidates(
      urls: [ApiConfig.authForgotPasswordUrl],
      body: {'email': normalizedEmail},
    );
  }

  Future<AuthResult> verifySignupOtp({
    required String email,
    required String otp,
  }) async {
    return _authenticateCandidates(
      urls: [ApiConfig.authVerifySignupOtpUrl],
      body: {'email': email.trim(), 'otp': otp.trim()},
    );
  }

  Future<AuthResult> verifyForgotOtp({
    required String email,
    required String otp,
  }) async {
    return _authenticateCandidates(
      urls: [ApiConfig.authVerifyForgotOtpUrl],
      body: {'email': email.trim(), 'otp': otp.trim()},
    );
  }

  Future<AuthResult> verifyChangePasswordOtp({
    required String email,
    required String otp,
  }) async {
    return _authenticateCandidates(
      urls: [
        ApiConfig.authVerifyChangePasswordOtpUrl,
        ApiConfig.authChangePasswordUrl,
      ],
      body: {'email': email.trim(), 'otp': otp.trim()},
    );
  }

  Future<AuthResult> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    String? confirmPassword,
  }) async {
    return _authenticateCandidates(
      urls: [ApiConfig.authResetPasswordUrl],
      body: {
        'email': email.trim(),
        'otp': otp.trim(),
        'password': newPassword,
        'new_password': newPassword,
        if (confirmPassword != null && confirmPassword.trim().isNotEmpty)
          'confirm_password': confirmPassword.trim(),
      },
    );
  }

  Future<AuthResult> sendChangePasswordOtp({required String email}) async {
    return _authenticateCandidates(
      urls: [ApiConfig.authSendChangePasswordOtpUrl],
      body: {'email': email.trim()},
    );
  }

  Future<AuthResult> changePassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
    required String otp,
  }) async {
    return _authenticateCandidates(
      urls: [ApiConfig.authChangePasswordUrl, ApiConfig.authConfirmPasswordUrl],
      body: {
        'email': email.trim(),
        'new_password': newPassword,
        'confirm_password': confirmPassword.trim(),
        'password_confirmation': confirmPassword.trim(),
        'otp': otp.trim(),
      },
    );
  }

  // CORE AUTH METHOD
  Future<AuthResult> _authenticateCandidates({
    required List<String> urls,
    required Map<String, dynamic> body,
  }) async {
    AuthResult? lastResult;

    for (final url in urls) {
      final result = await _authenticate(url: url, body: body);
      if (result.success) return result;

      lastResult = result;
      if (!_isEndpointMissing(result.message)) {
        return result;
      }
    }

    return lastResult ??
        const AuthResult(
          success: false,
          message: 'Unable to connect to server',
        );
  }

  bool _isEndpointMissing(String message) {
    final lowered = message.toLowerCase();
    return lowered.contains('404') ||
        lowered.contains('not found') ||
        lowered.contains('could not be found') ||
        lowered.contains('the route');
  }

  Future<AuthResult> _authenticate({
    required String url,
    required Map<String, dynamic> body,
  }) async {
    try {
      if (kDebugMode) {
        final safeBody = Map<String, dynamic>.from(body);
        if (safeBody.containsKey('password')) safeBody['password'] = '***';
        debugPrint('AUTH REQUEST -> $url');
        debugPrint('AUTH BODY -> $safeBody');
      }

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
      final Map<String, dynamic> data = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};

      if (kDebugMode) {
        debugPrint('AUTH STATUS -> ${response.statusCode}');
        debugPrint('AUTH RESPONSE -> ${response.body}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final token = _extractToken(data);
        final email = _extractEmail(data, body);
        final password = _extractPassword(body);
        final otp = _extractOtp(data);
        if (email != null && email.isNotEmpty) {
          await saveEmail(email);
        }
        if (password != null && password.isNotEmpty) {
          await savePassword(password);
        }
        if (token != null && token.isNotEmpty) {
          await saveToken(token);
          return AuthResult(
            success: true,
            message: _extractMessage(data) ?? 'Authentication successful',
            token: token,
            otp: otp,
          );
        }
        return AuthResult(
          success: true,
          message: _extractMessage(data) ?? 'Authentication successful',
          otp: otp,
        );
      }

      return AuthResult(
        success: false,
        message:
            _extractMessage(data) ??
            'Authentication failed (${response.statusCode})',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AUTH ERROR -> $e');
      }
      return const AuthResult(
        success: false,
        message: 'Unable to connect to server',
      );
    }
  }

  String? _extractToken(Map<String, dynamic> data) {
    final direct = data['token'] ?? data['access_token'];
    if (direct is String) return direct;

    final payload = data['data'];
    if (payload is Map<String, dynamic>) {
      final nested = payload['token'] ?? payload['access_token'];
      if (nested is String) return nested;
    }

    return null;
  }

  String? _extractMessage(Map<String, dynamic> data) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) return message;

    final errors = data['errors'];
    if (errors is Map<String, dynamic> && errors.isNotEmpty) {
      final firstError = errors.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        final value = firstError.first;
        if (value is String) return value;
      }
    }

    return null;
  }

  String? _extractEmail(
    Map<String, dynamic> data,
    Map<String, dynamic> requestBody,
  ) {
    final requestEmail = requestBody['email'];
    if (requestEmail is String && requestEmail.trim().isNotEmpty) {
      return requestEmail.trim();
    }

    final direct = data['email'];
    if (direct is String && direct.trim().isNotEmpty) return direct.trim();

    final payload = data['data'];
    if (payload is Map<String, dynamic>) {
      final nested = payload['email'];
      if (nested is String && nested.trim().isNotEmpty) return nested.trim();
    }

    return null;
  }

  String? _extractOtp(Map<String, dynamic> data) {
    final direct = data['otp'];
    if (direct != null) return direct.toString();

    final payload = data['data'];
    if (payload is Map<String, dynamic> && payload['otp'] != null) {
      return payload['otp'].toString();
    }

    return null;
  }

  String? _extractPassword(Map<String, dynamic> requestBody) {
    final direct = requestBody['password'];
    if (direct is String && direct.trim().isNotEmpty) return direct;

    final newPassword = requestBody['new_password'];
    if (newPassword is String && newPassword.trim().isNotEmpty) {
      return newPassword;
    }
    return null;
  }

  // SAVE TOKEN
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email.trim());
  }

  Future<void> savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passwordKey, password);
  }

  Future<void> saveSignupEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_signupEmailKey, email.trim());
  }

  Future<void> savePendingSignupData({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingSignupNameKey, name.trim());
    await prefs.setString(_pendingSignupEmailKey, email.trim());
    await prefs.setString(_pendingSignupPasswordKey, password);
    await prefs.setString(_pendingSignupPhoneKey, (phone ?? '').trim());
  }

  // GET TOKEN
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passwordKey);
  }

  Future<String?> getSignupEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_signupEmailKey);
  }

  Future<Map<String, String>> getPendingSignupData() async {
    final prefs = await SharedPreferences.getInstance();
    return <String, String>{
      'name': prefs.getString(_pendingSignupNameKey) ?? '',
      'email': prefs.getString(_pendingSignupEmailKey) ?? '',
      'password': prefs.getString(_pendingSignupPasswordKey) ?? '',
      'phone': prefs.getString(_pendingSignupPhoneKey) ?? '',
    };
  }

  Future<void> clearPendingSignupData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingSignupNameKey);
    await prefs.remove(_pendingSignupEmailKey);
    await prefs.remove(_pendingSignupPasswordKey);
    await prefs.remove(_pendingSignupPhoneKey);
  }

  // CHECK LOGIN
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);
    await prefs.remove(_signupEmailKey);
    await clearPendingSignupData();
  }
}
