import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:beeconnect_flutter/db/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final db = DatabaseHelper();
  late DateTime _currentMonth;
  late List<Inspection> _inspections;
  late Map<String, String> _hiveNames;
  late Map<String, String> _apiaryNames;
  late String? _loggedUsername;
  DateTime? _selectedDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _inspections = [];
    _hiveNames = {};
    _apiaryNames = {};
    
    initializeDateFormatting('pt_PT', null).then((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedUsername = prefs.getString('loggedUsername');
    
    if (_loggedUsername == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      _inspections.clear();
      _hiveNames.clear();
      _apiaryNames.clear();

      final apiaries = await db.getApiaries(_loggedUsername!);
      
      for (var apiary in apiaries) {
        _apiaryNames[apiary['id'].toString()] = apiary['name'];
      }

      // Get all hives for these apiaries
      for (var apiary in apiaries) {
        final apiaryId = apiary['id'].toString();
        final hives = await db.getHivesByApiary(apiaryId);
        
        for (var hive in hives) {
          _hiveNames[hive['id']] = hive['name'];
          
          // Get inspections for each hive
          final inspections = await db.getInspecoes(hive['id']);
          for (var insp in inspections) {
            try {
              final date = DateTime.parse(insp['data']!);
              _inspections.add(Inspection(
                hiveId: hive['id'],
                hiveName: hive['name'],
                apiaryId: apiaryId,
                apiaryName: apiary['name'],
                date: date,
                feeding: insp['alimentacao'] ?? '',
                treatments: insp['tratamentos'] ?? '',
                problems: insp['problemas'] ?? '',
                observations: insp['observacoes'] ?? '',
              ));
            } catch (e) {
              print('Error parsing date for inspection: $e');
            }
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  List<Inspection> _getInspectionsForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return _inspections.where((insp) {
      final inspDateStr = DateFormat('yyyy-MM-dd').format(insp.date);
      return inspDateStr == dateStr;
    }).toList();
  }

  List<DateTime?> _getDaysInMonth() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDay.weekday;

    final days = <DateTime?>[];

    for (var i = 1; i < firstWeekday; i++) {
      days.add(null);
    }
    for (var i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }

    return days;
  }

  Future<void> _showAddInspectionDialog(BuildContext context) async {
    final dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
    );
    final feedingController = TextEditingController();
    final treatmentsController = TextEditingController();
    final problemsController = TextEditingController();
    final observationsController = TextEditingController();

    final apiaries = await db.getApiaries(_loggedUsername!);
    String? selectedApiaryId;
    String? selectedHiveId;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Nova Inspeção'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Apiary Dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Apiário'),
                    items: apiaries.map<DropdownMenuItem<String>>((apiary) {
                      return DropdownMenuItem<String>(
                        value: apiary['id'].toString(),
                        child: Text(apiary['name']),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      selectedApiaryId = value;
                      selectedHiveId = null;
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Hive Dropdown
                  if (selectedApiaryId != null)
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: db.getHivesByApiary(selectedApiaryId!),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        final hives = snapshot.data!;
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Colmeia'),
                          items: hives.map<DropdownMenuItem<String>>((hive) {
                            return DropdownMenuItem<String>(
                              value: hive['id'],
                              child: Text(hive['name']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            selectedHiveId = value;
                            setState(() {});
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  
                  // Inspection Date
                  TextFormField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'Data da Inspeção',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        dateController.text = DateFormat('dd/MM/yyyy').format(date);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Feeding Information
                  TextFormField(
                    controller: feedingController,
                    decoration: const InputDecoration(
                      labelText: 'Alimentação',
                      hintText: 'Tipo e quantidade de alimentação'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  
                  // Treatments
                  TextFormField(
                    controller: treatmentsController,
                    decoration: const InputDecoration(
                      labelText: 'Tratamentos',
                      hintText: 'Tratamentos aplicados'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  
                  // Problems
                  TextFormField(
                    controller: problemsController,
                    decoration: const InputDecoration(
                      labelText: 'Problemas',
                      hintText: 'Problemas identificados'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  
                  // Observations
                  TextFormField(
                    controller: observationsController,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      hintText: 'Outras observações relevantes'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                ),
                onPressed: () async {
                  if (selectedHiveId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Por favor, selecione uma colmeia')),
                    );
                    return;
                  }

                  try {
                    final inspectionDate = DateFormat('dd/MM/yyyy').parse(dateController.text);

                    await db.insertInspecao(
                      hiveId: selectedHiveId!,
                      data: inspectionDate.toIso8601String(),
                      alimentacao: feedingController.text,
                      tratamentos: treatmentsController.text,
                      problemas: problemsController.text,
                      observacoes: observationsController.text,
                      proximaVisita: null,
                    );

                    await _loadData();
                    if (!mounted) return;
                    Navigator.pop(context);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro: $e')),
                    );
                  }
                },
                child: const Text(
                  'Guardar',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loggedUsername == null) {
      return const Scaffold(
        body: Center(child: Text('Por favor, faça login para ver o calendário')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        title: Row(
          children: [
            Image.asset(
              'assets/logo_beeconnect.png',
              height: 32,
            ),
            const SizedBox(width: 8),
            const Text("BeeConnect"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFC107),
        onPressed: () => _showAddInspectionDialog(context),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFFFC107),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/home');
              break;
            case 1:
              Navigator.pushNamed(context, '/statistics');
              break;
            case 2:
              Navigator.pushNamed(context, '/map_screen');
              break;
            case 3:
              Navigator.pushNamed(context, '/calendar');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bug_report), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: ''),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Month header and navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month - 1,
                        1,
                      );
                    });
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy', 'pt_PT').format(_currentMonth),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month + 1,
                        1,
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Weekday headers
            Row(
              children: ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            
            // Calendar grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 7,
                children: _getDaysInMonth().map((date) {
                  if (date == null) {
                    return const SizedBox.shrink();
                  }
                  
                  final inspections = _getInspectionsForDate(date);
                  final isToday = date.day == DateTime.now().day && 
                                 date.month == DateTime.now().month && 
                                 date.year == DateTime.now().year;
                  
                  return GestureDetector(
                    onTap: inspections.isNotEmpty
                        ? () => setState(() => _selectedDate = date)
                        : null,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isToday
                            ? Colors.amber.withOpacity(0.3)
                            : inspections.isNotEmpty
                                ? Colors.green.withOpacity(0.2)
                                : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              date.day.toString(),
                              style: TextStyle(
                                color: inspections.isNotEmpty
                                    ? Colors.green
                                    : null,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (inspections.isNotEmpty)
                              const Icon(
                                Icons.circle,
                                size: 4,
                                color: Colors.green,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            // Selected date inspections
            if (_selectedDate != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy').format(_selectedDate!),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _selectedDate = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._getInspectionsForDate(_selectedDate!).map((insp) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with apiary and hive info
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFC107).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Apiário: ${insp.apiaryName}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.home, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Colmeia: ${insp.hiveName}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Inspection details
                              if (insp.feeding.isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.restaurant, color: Colors.orange, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Alimentação:',
                                            style: TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          Text(insp.feeding),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              
                              if (insp.treatments.isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.medical_services, color: Colors.red, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Tratamentos:',
                                            style: TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          Text(insp.treatments),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              
                              if (insp.problems.isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.warning, color: Colors.red, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Problemas:',
                                            style: TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          Text(insp.problems),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              
                              if (insp.observations.isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.notes, color: Colors.blue, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Observações:',
                                            style: TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          Text(insp.observations),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Inspection {
  final String hiveId;
  final String hiveName;
  final String apiaryId;
  final String apiaryName;
  final DateTime date;
  final String feeding;
  final String treatments;
  final String problems;
  final String observations;

  Inspection({
    required this.hiveId,
    required this.hiveName,
    required this.apiaryId,
    required this.apiaryName,
    required this.date,
    required this.feeding,
    required this.treatments,
    required this.problems,
    required this.observations,
  });
}