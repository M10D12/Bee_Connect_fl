import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:beeconnect_flutter/db/database_helper.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isSubmitting = false;
  String errorMsg = '';

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
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
              onPressed: isSubmitting ? null : _handleRegister,
              child: isSubmitting
                  ? CircularProgressIndicator()
                  : Text('Register'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ), backgroundColor: Color(0xFFF8B42B),
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 100),
              ),
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

  Future<void> _handleRegister() async {
    setState(() {
      isSubmitting = true;
      errorMsg = '';
    });

    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isNotEmpty && password.isNotEmpty) {
      await _dbHelper.insertUser(username, password);
      Fluttertoast.showToast(msg: "Registration successful!");
      Navigator.pushReplacementNamed(context, '/login');
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
