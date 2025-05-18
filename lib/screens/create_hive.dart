import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:beeconnect_flutter/db/database_helper.dart';

class CreateHiveScreen extends StatefulWidget {
  final String apiaryId;
  final String apiaryName;

  const CreateHiveScreen({
    Key? key,
    required this.apiaryId,
    required this.apiaryName,
  }) : super(key: key);


  @override
  State<CreateHiveScreen> createState() => _CreateHiveScreenState();
}

class _CreateHiveScreenState extends State<CreateHiveScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String selectedType = 'Langstroth';
  String creationDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

  final List<String> typeOptions = [
    'Langstroth',
    'Lusitano',
    'Reversível',
    'Industrial (dadant)'
  ];

  void _saveHive() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty || description.isEmpty || creationDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preenche todos os campos")),
      );
      return;
    }

    final db = DatabaseHelper();
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insertHive(
      id: id,
      name: name,
      imageBase64: null, // ou adiciona imagem se quiseres futuramente
      apiaryId: widget.apiaryId,
      type: selectedType,
      creationDate: creationDate,
      description: description,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Colmeia criada com sucesso")),
    );
    Navigator.pop(context);
  }


  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        creationDate = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Criar Colmeia"),
        backgroundColor: const Color(0xFFFFC107),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nome da Colmeia"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: "Tipo"),
                items: typeOptions.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => selectedType = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Data de Criação",
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                onTap: _pickDate,
                controller: TextEditingController(text: creationDate),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Descrição"),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveHive,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text("Salvar", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
