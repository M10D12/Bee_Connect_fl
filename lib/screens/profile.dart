import 'package:flutter/material.dart';
import 'package:beeconnect_flutter/db/database_helper.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ADICIONADO

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = "Carregando...";
  String email = "Carregando...";
  String? profilePicBase64;

  final DatabaseHelper dbHelper = DatabaseHelper();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Carrega o perfil do usuário
  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedUsername = prefs.getString('loggedUsername');

    if (loggedUsername != null) {
      final user = await dbHelper.getUser(loggedUsername);
      if (user != null) {
        setState(() {
          username = user['username'];
          email = user['email'] ?? '';
          profilePicBase64 = user['profilePic']; // Se o perfil tiver imagem base64
        });
      }
    } else {
      // Se não houver user logado, volta para login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Função para escolher a imagem e convertê-la para Base64
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        profilePicBase64 = base64Encode(bytes);
      });
    }
  }

  // Função para salvar as alterações no banco de dados
  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedUsername = prefs.getString('loggedUsername');

    if (loggedUsername != null) {
      // Primeiro, obtemos o user ID
      final user = await dbHelper.getUser(loggedUsername);
      if (user != null) {
        await dbHelper.updateUserProfile(
          user['id'].toString(),
          username,
          email,
          profilePicBase64,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Perfil atualizado com sucesso")),
        );
      }
    }
  }

  // Função para logout
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedUsername');

    // Volta para o login
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil"),
        backgroundColor: const Color(0xFFFFC107),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                backgroundImage: profilePicBase64 != null
                    ? MemoryImage(Uint8List.fromList(base64Decode(profilePicBase64!)))
                    : const NetworkImage('https://example.com/default-avatar.png') as ImageProvider,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              username,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              email,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Salvar Perfil"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Logout", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
