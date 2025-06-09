import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:beeconnect_flutter/db/database_helper.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isSubmitting = false;
  String errorMsg = '';

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: isSubmitting ? null : _handleLogin,
              child: isSubmitting
                  ? CircularProgressIndicator()
                  : Text('Login'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ), backgroundColor: Color(0xFFF8B42B),
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 100),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: Text("Não tem conta? Registar", style: TextStyle(color: Color(0xFFF8B42B))),
            ),
            if (errorMsg.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  errorMsg,
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() {
      isSubmitting = true;
      errorMsg = '';
    });

    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isNotEmpty && password.isNotEmpty) {
      final user = await _dbHelper.getUser(username);

      if (user != null && user['password'] == password) {
        // Navigate to home page or dashboard
        Fluttertoast.showToast(msg: "Login successful!");
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          errorMsg = 'Invalid username or password';
        });
      }
    } else {
      setState(() {
        errorMsg = 'Please fill in both fields';
      });
    }

    setState(() {
      isSubmitting = false;
    });
  }
}
