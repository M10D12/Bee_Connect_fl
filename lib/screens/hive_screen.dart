import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ColmeiaScreen extends StatefulWidget {
  final String colmeiaId;
  const ColmeiaScreen({required this.colmeiaId});

  @override
  State<ColmeiaScreen> createState() => _ColmeiaScreenState();
}

class _ColmeiaScreenState extends State<ColmeiaScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _realtimeDb = FirebaseDatabase.instance;

  String nome = '';
  String tipo = '';
  String descricao = '';
  int alcas = 0;

  Map<String, dynamic> sensorData = {};
  List<Map<String, dynamic>> historico = [];

  bool showInspecaoForm = false;

  String dataInspecao = '';
  String alimentacao = '';
  String tratamentos = '';
  String problemas = '';
  String observacoes = '';
  String proximaVisita = '';

  int currentPage = 0;
  int itemsPerPage = 3;

  List<String> typeOptions = ["Langstroth", "Lusitano", "Reversível", "Industrial (dadant)"];

  @override
  void initState() {
    super.initState();
    _loadColmeiaData();
    _listenToRealtimeData();
    _loadHistorico();
  }

  Future<void> _loadColmeiaData() async {
    try {
      final doc = await _firestore.collection('colmeia').doc(widget.colmeiaId).get();
      setState(() {
        nome = doc['nome'] ?? '';
        tipo = doc['tipo'] ?? '';
        descricao = doc['descricao'] ?? '';
        alcas = (doc['alcas'] ?? 0).toInt();
      });
    } catch (e) {
      print('Erro carregar colmeia: $e');
    }
  }

  void _listenToRealtimeData() {
    _realtimeDb.ref('colmeias/colmeia1').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          sensorData = Map<String, dynamic>.from(data);
        });
      }
    });
  }

  Future<void> _loadHistorico() async {
    try {
      final result = await _firestore
          .collection('colmeia')
          .doc(widget.colmeiaId)
          .collection('inspecoes')
          .orderBy('data', descending: true)
          .get();

      setState(() {
        historico = result.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      print('Erro carregar histórico: $e');
    }
  }

  Future<void> _salvarColmeia() async {
    await _firestore.collection('colmeia').doc(widget.colmeiaId).update({
      'nome': nome,
      'tipo': tipo,
      'descricao': descricao,
      'alcas': alcas,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Informações atualizadas!')),
    );
  }

  Future<void> _adicionarInspecao() async {
    final inspecao = {
      'data': dataInspecao,
      'alimentacao': alimentacao,
      'tratamentos': tratamentos,
      'problemas': problemas,
      'observacoes': observacoes,
      if (proximaVisita.isNotEmpty) 'proxima_visita': proximaVisita,
    };

    await _firestore
        .collection('colmeia')
        .doc(widget.colmeiaId)
        .collection('inspecoes')
        .add(inspecao);

    setState(() {
      historico.insert(0, inspecao);
      dataInspecao = '';
      alimentacao = '';
      tratamentos = '';
      problemas = '';
      observacoes = '';
      proximaVisita = '';
      showInspecaoForm = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Inspeção adicionada!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pagedHistorico = [
      for (var i = 0; i < historico.length; i += itemsPerPage)
        historico.sublist(i, (i + itemsPerPage).clamp(0, historico.length))
    ];

    final currentInspecoes = pagedHistorico.isNotEmpty ? pagedHistorico[currentPage] : [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestão da Colmeia'),
        leading: BackButton(),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          TextField(
            decoration: InputDecoration(labelText: 'Nome'),
            controller: TextEditingController(text: nome),
            onChanged: (value) => nome = value,
          ),
          DropdownButtonFormField<String>(
            value: tipo.isNotEmpty ? tipo : null,
            items: typeOptions.map((opt) {
              return DropdownMenuItem(value: opt, child: Text(opt));
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => tipo = value);
            },
            decoration: InputDecoration(labelText: 'Tipo'),
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Descrição'),
            controller: TextEditingController(text: descricao),
            onChanged: (value) => descricao = value,
          ),
          Row(
            children: [
              Text('Número de Alças: $alcas'),
              Spacer(),
              IconButton(
                onPressed: () => setState(() => alcas = (alcas > 0) ? alcas - 1 : 0),
                icon: Icon(Icons.remove),
              ),
              IconButton(
                onPressed: () => setState(() => alcas += 1),
                icon: Icon(Icons.add),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _salvarColmeia,
            child: Text('Salvar'),
          ),
          Divider(height: 32),

          Text('📡 Dados em Tempo Real da Colmeia', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('📍 Localização: ${sensorData['localizacao'] ?? ''}'),
          Text('🌡️ Temperatura: ${sensorData['temperatura'] ?? ''}'),
          Text('🔊 Nível de Som: ${sensorData['nivelSom'] ?? ''}'),
          Text('💡 Luminosidade: ${sensorData['sensores']?['Luminosidade'] ?? '—'}'),

          Divider(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Histórico de Inspeções', style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => setState(() => showInspecaoForm = !showInspecaoForm),
                child: Text(showInspecaoForm ? 'Fechar' : '+ Nova Inspeção'),
              ),
            ],
          ),

          if (showInspecaoForm) ...[
            TextField(
              decoration: InputDecoration(labelText: 'Data da Inspeção'),
              controller: TextEditingController(text: dataInspecao),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    dataInspecao = DateFormat('dd/MM/yyyy').format(date);
                  });
                }
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Alimentação'),
              onChanged: (value) => alimentacao = value,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Tratamentos'),
              onChanged: (value) => tratamentos = value,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Problemas / Doenças'),
              onChanged: (value) => problemas = value,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Observações'),
              onChanged: (value) => observacoes = value,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Programar próxima visita (opcional)'),
              controller: TextEditingController(text: proximaVisita),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                    setState(() {
                      proximaVisita = DateFormat('dd/MM/yyyy HH:mm').format(dt);
                    });
                  }
                }
              },
            ),
            ElevatedButton(
              onPressed: _adicionarInspecao,
              child: Text('Adicionar Inspeção'),
            ),
            Divider(height: 32),
          ],

          ...currentInspecoes.map((inspecao) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📅 ${inspecao['data'] ?? ''}', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('🍯 Alimentação: ${inspecao['alimentacao'] ?? ''}'),
                    Text('🧪 Tratamentos: ${inspecao['tratamentos'] ?? ''}'),
                    Text('🐝 Problemas: ${inspecao['problemas'] ?? ''}'),
                    Text('📝 Observações: ${inspecao['observacoes'] ?? ''}'),
                    if (inspecao['proxima_visita'] != null)
                      Text('📌 Próxima visita: ${inspecao['proxima_visita']}'),
                  ],
                ),
              ),
            );
          }).toList(),

          if (pagedHistorico.length > 1) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    if (currentPage > 0) setState(() => currentPage--);
                  },
                  child: Text('← Anterior'),
                ),
                Text('Página ${currentPage + 1} de ${pagedHistorico.length}'),
                TextButton(
                  onPressed: () {
                    if (currentPage < pagedHistorico.length - 1) setState(() => currentPage++);
                  },
                  child: Text('Seguinte →'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
