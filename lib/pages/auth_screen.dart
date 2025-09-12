import 'package:flutter/material.dart';
import 'package:fleet_management/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State createState() => _AuthScreenState();
}

class _AuthScreenState extends State {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLogin = true;
  String message = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLogin ? "Welcome Back" : "Create Account",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLogin
                          ? "Login with your email & password"
                          : "Register with your details",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.black,
                        ),
                        onPressed: () async {
                          if (isLogin) {
                            var user = await _authService.loginWithEmail(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );
                            if (user == null) {
                              if (mounted) {
                                setState(() => message = "Login failed ❌");
                              }
                            }
                          } else {
                            var user = await _authService.registerWithEmail(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );
                            if (user == null) {
                              if (mounted) {
                                setState(() => message = "Register failed ❌");
                              }
                            }
                          }
                        },
                        child: Text(
                          isLogin ? "Login" : "Register",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () =>
                          setState(() => isLogin = !isLogin),
                      child: Text(
                        isLogin
                            ? "Don't have an account? Register"
                            : "Already registered? Login",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (message.isNotEmpty)
                      Text(
                        message,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
