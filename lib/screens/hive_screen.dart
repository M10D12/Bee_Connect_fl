import 'dart:async';
import 'dart:typed_data';
import 'package:beeconnect_flutter/db/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';


class HiveScreen extends StatefulWidget {
  final String hiveId;
  const HiveScreen({required this.hiveId});

  @override
  State<HiveScreen> createState() => _HiveScreenState();
}

class _HiveScreenState extends State<HiveScreen> {
  final db = DatabaseHelper();

  String nome = '';
  String tipo = '';
  String descricao = '';
  int alcas = 0;

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

  // --- SENSOR BLE ---
  final flutterReactiveBle = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? scanSubscription;
  double? sensorTemperature;
  int? sensorHumidity;

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  Timer? scanTimer;

  @override
  void initState() {
    super.initState();
    _requestPermissions().then((_) {
      _loadHiveData();
      _loadHistorico();
      _startSensorScan();
      scanTimer = Timer.periodic(Duration(seconds: 10), (_) => _startSensorScan());
    });
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    scanTimer?.cancel();
    super.dispose();
  }


  Future<void> _loadHiveData() async {
    final result = await db.database.then((dbInstance) {
      return dbInstance.query(
        'hives',
        where: 'id = ?',
        whereArgs: [widget.hiveId],
        limit: 1,
      );
    });

    if (result.isNotEmpty) {
      final hive = result.first;
      setState(() {
        nome = hive['name'] as String? ?? '';
        tipo = hive['type'] as String? ?? '';
        descricao = hive['description'] as String? ?? '';
        alcas = hive['alcas'] != null ? hive['alcas'] as int : 0;
      });
    }
  }

  Future<void> _loadHistorico() async {
    final result = await db.getInspecoes(widget.hiveId);
    setState(() {
      historico = result;
    });
  }

  Future<void> _salvarHive() async {
    await db.database.then((dbInstance) {
      dbInstance.update(
        'hives',
        {
          'name': nome,
          'type': tipo,
          'description': descricao,
          'alcas': alcas,
        },
        where: 'id = ?',
        whereArgs: [widget.hiveId],
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Informações atualizadas!')),
    );
  }

  Future<void> _adicionarInspecao() async {
    await db.insertInspecao(
      hiveId: widget.hiveId,
      data: dataInspecao,
      alimentacao: alimentacao,
      tratamentos: tratamentos,
      problemas: problemas,
      observacoes: observacoes,
      proximaVisita: proximaVisita.isNotEmpty ? proximaVisita : null,
    );

    await _loadHistorico();

    setState(() {
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

  // --- SENSOR BLE ---
  void _startSensorScan() {
    scanSubscription?.cancel();
    scanSubscription = flutterReactiveBle.scanForDevices(
      withServices: [],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      if (device.manufacturerData.length >= 13 &&
          device.manufacturerData[0] == 0x69 &&
          device.manufacturerData[1] == 0x09) {
        try {
          double temp = _parseTemperature(device.manufacturerData);
          int hum = _parseHumidity(device.manufacturerData);

          setState(() {
            sensorTemperature = temp;
            sensorHumidity = hum;
          });

          scanSubscription?.cancel(); // para o scan depois de obter dados
        } catch (e) {
          print('Error parsing sensor data: $e');
        }
      }
    }, onError: (err) {
      print('Scan error: $err');
    });
  }

  double _parseTemperature(Uint8List data) {
    double mantissa = (data[10] & 0x0F) * 0.1 + (data[11] & 0x7F);
    int sign = (data[11] & 0x80) > 0 ? 1 : -1;
    return mantissa * sign;
  }

  int _parseHumidity(Uint8List data) {
    return data[12] & 0x7F;
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
            onPressed: _salvarHive,
            child: Text('Salvar'),
          ),
          Divider(height: 32),

          // DADOS SENSOR SWITCHBOT
          Text('📡 Dados do Sensor SwitchBot', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Card(
            color: Colors.amber[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🌡️ Temperatura: ${sensorTemperature != null ? "${sensorTemperature!.toStringAsFixed(1)} ºC" : "A procurar..."}'),
                  Text('💧 Humidade: ${sensorHumidity != null ? "$sensorHumidity %" : "A procurar..."}'),
                ],
              ),
            ),
          ),

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
