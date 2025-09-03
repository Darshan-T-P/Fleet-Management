import 'package:flutter/material.dart';
import 'package:fleet_management/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLogin = true;
  String message = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? "Login" : "Register")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (isLogin) {
                  var user = await _authService.loginWithEmail(
                    _emailController.text.trim(),
                    _passwordController.text.trim(),
                  );
                  if (user == null) {
                    if (mounted) setState(() => message = "Login failed ❌");
                  }
                } else {
                  var user = await _authService.registerWithEmail(
                    _emailController.text.trim(),
                    _passwordController.text.trim(),
                  );
                  if (user == null) {
                    if (mounted) setState(() => message = "Register failed ❌");
                  }
                }
              },
              child: Text(isLogin ? "Login" : "Register"),
            ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(
                isLogin
                    ? "Don't have an account? Register"
                    : "Already registered? Login",
              ),
            ),
            const SizedBox(height: 20),
            Text(message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
