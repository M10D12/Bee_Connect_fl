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
      // Clear existing data
      _inspections.clear();
      _hiveNames.clear();
      _apiaryNames.clear();

      // Load all inspections for the user's hives
      final apiaries = await db.getApiaries(_loggedUsername!);
      
      // Create apiary name map
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
            if (insp['proxima_visita'] != null) {
              try {
                final date = DateTime.parse(insp['proxima_visita']!);
                _inspections.add(Inspection(
                  hiveId: hive['id'],
                  hiveName: hive['name'],
                  apiaryId: apiaryId,
                  apiaryName: apiary['name'],
                  date: date,
                ));
              } catch (e) {
                // Handle date parsing error
              }
            }
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      });
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

    // Create a growable list
    final days = <DateTime?>[];

    // Add null for days before the first day of the month
    for (var i = 1; i < firstWeekday; i++) {
      days.add(null);
    }

    // Add all days of the month
    for (var i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }

    return days;
  }

  Future<void> _showAddInspectionDialog(BuildContext context) async {
    final dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
    );
    final timeController = TextEditingController(
      text: DateFormat('HH:mm').format(DateTime.now()),
    );

    final apiaries = await db.getApiaries(_loggedUsername!);
    String? selectedApiaryId;
    String? selectedHiveId;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Agendar Inspeção'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  TextFormField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'Data',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        dateController.text = DateFormat('dd/MM/yyyy').format(date);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: timeController,
                    decoration: const InputDecoration(
                      labelText: 'Hora',
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        timeController.text = time.format(context);
                      }
                    },
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
                  if (selectedHiveId == null) return;

                  try {
                    final dateTimeStr = '${dateController.text} ${timeController.text}';
                    final dateTime = DateFormat('dd/MM/yyyy HH:mm').parse(dateTimeStr);

                    await db.insertInspecao(
                      hiveId: selectedHiveId!,
                      data: DateTime.now().toIso8601String(),
                      alimentacao: '',
                      tratamentos: '',
                      problemas: '',
                      observacoes: '',
                      proximaVisita: dateTime.toIso8601String(),
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
                  'Agendar',
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
                      ..._getInspectionsForDate(_selectedDate!).map((insp) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Apiário: ${insp.apiaryName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Colmeia: ${insp.hiveName}'),
                          const SizedBox(height: 8),
                        ],
                      )),
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

  Inspection({
    required this.hiveId,
    required this.hiveName,
    required this.apiaryId,
    required this.apiaryName,
    required this.date,
  });
}