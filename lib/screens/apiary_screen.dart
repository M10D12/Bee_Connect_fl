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
  List<Map<String, dynamic>> forecast = [];

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
        'https://api.openweathermap.org/data/2.5/weather?lat=${widget.latitude}&lon=${widget.longitude}&units=metric&appid=f907eff41b9ba822e28fcdf74b6c537c&lang=pt';
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
        'https://api.openweathermap.org/data/2.5/forecast?lat=${widget.latitude}&lon=${widget.longitude}&units=metric&appid=f907eff41b9ba822e28fcdf74b6c537c&lang=pt';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List list = data['list'];
      final Set<String> seenDays = {};
      List<Map<String, dynamic>> result = [];

      for (var item in list) {
        final dt = item['dt_txt'];
        if (dt.contains("12:00:00")) {
          final day = dt.split(" ")[0];
          if (!seenDays.contains(day)) {
            final temp = item['main']['temp'].toInt();
            final desc = item['weather'][0]['description'];
            final icon = item['weather'][0]['icon'];
            result.add({
              'day': day.split("-").last, 
              'temp': temp,
              'desc': desc,
              'icon': icon,
            });
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
          _refreshHives();
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
            const SizedBox(height: 16),
            const Text(
              "Previsão dos próximos dias:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SizedBox(
  height: 150, 
  child: forecast.isEmpty
      ? const Center(child: CircularProgressIndicator())
      : ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: forecast.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final dayForecast = forecast[index];
            return SizedBox(
              width: 110,
              child: Card(
                color : Colors.amber[50],
                elevation: 3,
                margin: EdgeInsets.zero, 
                child: Padding(
                  padding: const EdgeInsets.all(6.0), 
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                    mainAxisSize: MainAxisSize.min, 
                    children: [
                      Text(
                        dayForecast['day'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14, 
                        ),
                      ),
                      SizedBox(
                        height: 40, 
                        child: Image.network(
                          'https://openweathermap.org/img/wn/${dayForecast['icon']}@2x.png',
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.error), 
                        ),
                      ),
                      Text(
                        "${dayForecast['temp']}°C",
                        style: const TextStyle(fontSize: 14), 
                      ),
                      SizedBox(
                        height: 30, 
                        child: Text(
                          dayForecast['desc'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
),
            const SizedBox(height: 16),
            const Text(
              "Colmeias:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
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
                            _refreshHives();
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