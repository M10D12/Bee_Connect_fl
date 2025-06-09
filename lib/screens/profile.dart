import 'package:flutter/material.dart';
import 'package:beeconnect_flutter/db/database_helper.dart'; // Certifique-se de que o DatabaseHelper está importado
import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

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
    // Aqui, você obtém o ID do usuário logado. Este ID pode ser armazenado no banco de dados ou ser gerado no login.
    // Vamos assumir que o "userId" é armazenado na base de dados após o login.
    final userId = await _getUserId(); // Substitua pelo método adequado para obter o ID do usuário logado.

    if (userId != null) {
      final user = await dbHelper.getUser(userId); // Método no DatabaseHelper que retorna os dados do usuário pelo ID
      if (user != null) {
        setState(() {
          username = user['username'];
          email = user['email'];
          profilePicBase64 = user['profilePic']; // Se o perfil tiver imagem base64
        });
      }
    }
  }

  // Método para buscar o ID do usuário. (Adapte ao seu fluxo de login)
  Future<String?> _getUserId() async {
    // Aqui você pode ter a lógica para pegar o usuário logado
    // Exemplo: Você pode armazenar o ID do usuário no SharedPreferences ou em uma tabela
    // e pegar essa informação na tela do perfil.
    return "user123"; // Apenas um exemplo.
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
    final userId = await _getUserId();

    if (userId != null) {
      await dbHelper.updateUserProfile(
        userId, 
        username, 
        email, 
        profilePicBase64
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Perfil atualizado com sucesso"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Perfil"),
        backgroundColor: Color(0xFFFFC107),
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
                backgroundColor: Color(0xFFFFC107),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Salvar Perfil"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle logout logic here
                Navigator.pushReplacementNamed(context, '/login');
              },
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
