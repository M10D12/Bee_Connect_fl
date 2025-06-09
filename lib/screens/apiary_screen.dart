import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:beeconnect_flutter/db/database_helper.dart';

class ApiaryScreen extends StatefulWidget {
  final String apiaryId;
  final String apiaryName;
  final double latitude;
  final double longitude;

  const ApiaryScreen({
    Key? key,
    required this.apiaryId,
    required this.apiaryName,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  State<ApiaryScreen> createState() => _ApiaryScreenState();
}

class _ApiaryScreenState extends State<ApiaryScreen> {
  final db = DatabaseHelper();
  late Future<List<Map<String, dynamic>>> _hivesFuture;
  String temperature = "--";
  String weatherInfo = "A obter...";
  List<String> forecast = [];

  @override
  void initState() {
    super.initState();
    _refreshHives();
    fetchWeather();
    fetchForecast();
  }

  void _refreshHives() {
    setState(() {
      _hivesFuture = db.getHivesByApiary(widget.apiaryId);
    });
  }

  void fetchWeather() async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=${widget.latitude}&lon=${widget.longitude}&units=metric&appid=YOUR_API_KEY&lang=pt';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        temperature = "${data['main']['temp'].toInt()}°";
        weatherInfo = "Vento ${data['wind']['speed']}km/h  Hum ${data['main']['humidity']}%";
      });
    }
  }

  void fetchForecast() async {
    final url =
        'https://api.openweathermap.org/data/2.5/forecast?lat=${widget.latitude}&lon=${widget.longitude}&units=metric&appid=YOUR_API_KEY&lang=pt';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List list = data['list'];
      final Set<String> seenDays = {};
      List<String> result = [];

      for (var item in list) {
        final dt = item['dt_txt'];
        if (dt.contains("12:00:00")) {
          final day = dt.split(" ")[0];
          if (!seenDays.contains(day)) {
            final temp = item['main']['temp'].toInt();
            final desc = item['weather'][0]['description'];
            result.add("$day: $temp°C, $desc");
            seenDays.add(day);
          }
        }
        if (result.length == 5) break;
      }
      setState(() {
        forecast = result;
      });
    }
  }

  void _deleteHive(String id) async {
    await db.deleteHive(id);
    _refreshHives();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        title: Text("Apiário ${widget.apiaryName}"),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () async {
          await Navigator.pushNamed(
            context,
            '/createHive',
            arguments: {
              'apiaryId': widget.apiaryId,
              'apiaryName': widget.apiaryName,
            },
          );
          _refreshHives(); // <- chama quando voltar da página CreateHiveScreen
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.amber[50],
              child: ListTile(
                title: Text("Hoje: $temperature"),
                subtitle: Text(weatherInfo),
              ),
            ),
            const SizedBox(height: 8),
            const Text("Previsão dos próximos dias:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            forecast.isEmpty
                ? const Text("A obter...")
                : Column(
                    children: forecast.map((e) => Text(e)).toList(),
                  ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _hivesFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final hives = snapshot.data!;
                  if (hives.isEmpty) return const Center(child: Text("Sem colmeias associadas."));
                  return ListView.separated(
                    itemCount: hives.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final hive = hives[index];
                      return Card(
                        child: ListTile(
                          title: Text(hive['name'] ?? 'Sem nome'),
                          subtitle: Text("Tipo: ${hive['type'] ?? ''}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteHive(hive['id']),
                          ),
                          onTap: () async {
                            await Navigator.pushNamed(
                              context,
                              '/hiveScreen',
                              arguments: {
                                'hiveId': hive['id'],
                              },
                            );
                            _refreshHives();  // <- quando voltas, recarrega a lista
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
