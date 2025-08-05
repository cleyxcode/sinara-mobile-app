// lib/screens/login_screen.dart (FIXED - Token Parsing)
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'register_screen.dart';
import 'main_screen.dart';

class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  static Future<void> saveAuthData(String token, Map<String, dynamic> user) async {
    _memoryToken = token;
    _memoryUser = user;
    print('TokenManager: Data saved - Token: $token, User: $user');
  }

  static String? _memoryToken;
  static Map<String, dynamic>? _memoryUser;

  static Future<String?> getToken() async {
    print('TokenManager: Retrieved token: $_memoryToken');
    return _memoryToken;
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    print('TokenManager: Retrieved user: $_memoryUser');
    return _memoryUser;
  }

  static Future<void> clearAuthData() async {
    _memoryToken = null;
    _memoryUser = null;
    print('TokenManager: Auth data cleared');
  }

  static Future<bool> isLoggedIn() async {
    final isLoggedIn = _memoryToken != null && _memoryToken!.isNotEmpty;
    print('TokenManager: Is logged in: $isLoggedIn');
    return isLoggedIn;
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final String baseUrl = 'https://sinara.space';

  @override
  void initState() {
    super.initState();
    _checkExistingAuth();
  }

  Future<void> _checkExistingAuth() async {
    final isLoggedIn = await TokenManager.isLoggedIn();
    if (isLoggedIn) {
      final token = await TokenManager.getToken();
      final user = await TokenManager.getUserData();
      
      if (token != null && user != null) {
        print('Existing auth found, navigating to MainScreen');
        _navigateToMainScreen(token, user);
      }
    }
  }

  void _navigateToMainScreen(String token, Map<String, dynamic> user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          token: token,
          user: user,
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Attempting login...');
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // PERBAIKAN: Parse response yang benar sesuai struktur Laravel
        String? token;
        Map<String, dynamic>? user;
        
        // Cek apakah response memiliki struktur dengan 'data'
        if (responseData.containsKey('data')) {
          // Struktur: {"success": true, "data": {"token": "...", "user": {...}}}
          final data = responseData['data'];
          token = data['token']?.toString();
          user = data['user'] as Map<String, dynamic>?;
        } else {
          // Struktur langsung: {"token": "...", "user": {...}}
          token = responseData['token']?.toString();
          user = responseData['user'] as Map<String, dynamic>?;
        }
        
        print('Parsed Token: $token');
        print('Parsed User: $user');
        
        if (token != null && token.isNotEmpty && user != null) {
          // Save auth data
          await TokenManager.saveAuthData(token, user);
          
          _showSnackBar('Login berhasil!', Colors.green);
          
          // Navigate to MainScreen
          _navigateToMainScreen(token, user);
        } else {
          print('Token or User is null/empty');
          print('Raw response data: $responseData');
          _showSnackBar('Data login tidak lengkap', Colors.red);
        }
        
      } else {
        // Login gagal
        String message = 'Login gagal';
        if (responseData.containsKey('message')) {
          message = responseData['message'];
        } else if (responseData.containsKey('data') && 
                   responseData['data'].containsKey('message')) {
          message = responseData['data']['message'];
        }
        _showSnackBar(message, Colors.red);
      }
    } catch (e) {
      print('Login Error: $e');
      _showSnackBar('Terjadi kesalahan: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo atau Title
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.local_hospital,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'SINARA',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'Kanker Serviks',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Masuk ke akun Anda',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 32),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Masukkan email Anda',
                          prefixIcon: Icon(Icons.email, color: Colors.green[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.green[600]!),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Masukkan password Anda',
                          prefixIcon: Icon(Icons.lock, color: Colors.green[600]),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.green[600]!),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password tidak boleh kosong';
                          }
                          if (value.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Forgot Password
                      TextButton(
                        onPressed: () {
                          _showSnackBar('Fitur belum tersedia', Colors.orange);
                        },
                        child: Text(
                          'Lupa Password?',
                          style: TextStyle(color: Colors.green[600]),
                        ),
                      ),
                      SizedBox(height: 8),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Belum punya akun? ',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Daftar',
                              style: TextStyle(
                                color: Colors.green[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}