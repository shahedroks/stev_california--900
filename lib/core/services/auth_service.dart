import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:renizo/core/constants/api_control/auth_api.dart';
import 'package:renizo/core/constants/api_control/global_api.dart';

/// Response model for signup API
class SignupResponse {
  final String status;
  final String message;
  final SignupData? data;

  SignupResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null ? SignupData.fromJson(json['data']) : null,
    );
  }
}

class SignupData {
  final UserData user;
  final Tokens tokens;

  SignupData({
    required this.user,
    required this.tokens,
  });

  factory SignupData.fromJson(Map<String, dynamic> json) {
    return SignupData(
      user: UserData.fromJson(json['user']),
      tokens: Tokens.fromJson(json['tokens']),
    );
  }
}

class UserData {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String avatarUrl;
  final String role;
  final String status;
  final bool isBlocked;
  final String? lastSelectedTownId;
  final String createdAt;

  UserData({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.role,
    required this.status,
    required this.isBlocked,
    this.lastSelectedTownId,
    required this.createdAt,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      isBlocked: json['isBlocked'] ?? false,
      lastSelectedTownId: json['lastSelectedTownId'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class Tokens {
  final String accessToken;

  Tokens({
    required this.accessToken,
  });

  factory Tokens.fromJson(Map<String, dynamic> json) {
    return Tokens(
      accessToken: json['accessToken'] ?? '',
    );
  }
}

/// Auth Service for API calls
class AuthService {
  /// Login – POST /api/v1/auth/login with email + password.
  /// Response has same shape as signup (status, message, data.user, data.tokens).
  static Future<SignupResponse> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(AuthAPIController.authLogin);
    final body = jsonEncode({
      'email': email,
      'password': password,
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return SignupResponse.fromJson(jsonResponse);
    } else {
      final errorBody = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {'message': 'Login failed'};
      throw Exception(errorBody['message'] ?? 'Login failed');
    }
  }

  /// Signup user
  static Future<SignupResponse> signup({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    // Use /auth/signup as shown in the image
    // If your API uses /users/signup, change this to: '$api/users/signup'
    final url = Uri.parse('$api/auth/signup');
    
    final body = jsonEncode({
      'fullName': fullName,
      'email': email,
      'password': password,
      'phone': phone,
      'role': role,
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return SignupResponse.fromJson(jsonResponse);
    } else {
      final errorBody = response.body.isNotEmpty 
          ? jsonDecode(response.body) 
          : {'message': 'Signup failed'};
      throw Exception(errorBody['message'] ?? 'Signup failed');
    }
  }
}
