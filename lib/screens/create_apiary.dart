import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:beeconnect_flutter/db/database_helper.dart';

class CreateApiaryScreen extends StatefulWidget {
  const CreateApiaryScreen({super.key});

  @override
  State<CreateApiaryScreen> createState() => _CreateApiaryScreenState();
}

class _CreateApiaryScreenState extends State<CreateApiaryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String selectedEnv = "Rural";

  double latitude = 40.6405;
  double longitude = -8.6538;

  XFile? _selectedImage;
  Uint8List? _imageBytes;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes(); 
      setState(() {
        _selectedImage = picked;
        _imageBytes = bytes;
      });
    }
  }

  void _onSave() async {
  if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Preenche todos os campos obrigatórios")),
    );
    return;
  }

  String? base64Image = _imageBytes != null ? base64Encode(_imageBytes!) : null;

  // Instanciar o helper
  final db = DatabaseHelper();

  // Inserir na base de dados
  await db.insertApiary(
    DateTime.now().millisecondsSinceEpoch.toString(), // ID único
    _nameController.text,
    _addressController.text,
    selectedEnv,
    latitude,
    longitude,
    base64Image,
  );

  // Mensagem de sucesso
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Apiário criado com sucesso!")),
  );

  // Voltar à página inicial
  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
}


  @override
  Widget build(BuildContext context) {
    final latLng = LatLng(latitude, longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Criar Apiário"),
        backgroundColor: const Color(0xFFFFC107),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nome do Apiário"),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: "Endereço"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    final query = _addressController.text;
                    if (query.isNotEmpty) {
                      try {
                        final locations = await locationFromAddress(query);
                        if (locations.isNotEmpty) {
                          final loc = locations.first;
                          setState(() {
                            latitude = loc.latitude;
                            longitude = loc.longitude;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Endereço encontrado e centralizado no mapa")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Endereço não encontrado")),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Erro: ${e.toString()}")),
                        );
                      }
                    }
                  },
                )
              ],
            ),

            const SizedBox(height: 16),
            const Text("Meio envolvente"),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChoiceChip(
                  label: const Text("Rural"),
                  selected: selectedEnv == "Rural",
                  onSelected: (_) => setState(() => selectedEnv = "Rural"),
                ),
                ChoiceChip(
                  label: const Text("Urbano"),
                  selected: selectedEnv == "Urbano",
                  onSelected: (_) => setState(() => selectedEnv = "Urbano"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _imageBytes!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(child: Text("Selecionar imagem")),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Mapa"),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  center: latLng,
                  zoom: 13.0,
                  onTap: (tapPosition, point) {
                    setState(() {
                      latitude = point.latitude;
                      longitude = point.longitude;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: latLng,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_pin, color: Colors.red, size: 40), // ← CORREÇÃO AQUI
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: latitude.toStringAsFixed(6),
                    decoration: const InputDecoration(labelText: "Latitude"),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) {
                        setState(() => latitude = parsed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: longitude.toStringAsFixed(6),
                    decoration: const InputDecoration(labelText: "Longitude"),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) {
                        setState(() => longitude = parsed);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              child: const Text("Criar Apiário", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
