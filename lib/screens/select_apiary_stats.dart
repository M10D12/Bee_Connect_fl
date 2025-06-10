import 'package:flutter/material.dart';
import 'package:beeconnect_flutter/db/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectApiaryForStatisticsScreen extends StatefulWidget {
  const SelectApiaryForStatisticsScreen({super.key});

  @override
  State<SelectApiaryForStatisticsScreen> createState() => _SelectApiaryForStatisticsScreenState();
}

class _SelectApiaryForStatisticsScreenState extends State<SelectApiaryForStatisticsScreen> {
  final db = DatabaseHelper();
  late Future<List<Map<String, dynamic>>> _apiariesFuture;
  String? loggedUsername;

  @override
  void initState() {
    super.initState();
    _loadLoggedUser();
  }

  Future<void> _loadLoggedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('loggedUsername');

    if (username != null) {
      setState(() {
        loggedUsername = username;
      });
      _refreshApiaries(username);
    }
  }

  void _refreshApiaries(String username) {
    setState(() {
      _apiariesFuture = db.getApiaries(username);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Selecionar Apiário"),
        backgroundColor: const Color(0xFFFFC107),
      ),
      body: loggedUsername == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _apiariesFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final apiaries = snapshot.data!;
                  if (apiaries.isEmpty) {
                    return const Center(
                        child: Text("Ainda não tens nenhum apiário registado 🐝"));
                  }
                  return ListView.separated(
                    itemCount: apiaries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final apiary = apiaries[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: ListTile(
                          title: Text(
                            apiary['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(apiary['location']),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/statistics',
                              arguments: {
                                'apiaryId': apiary['id'].toString(),
                                'apiaryName': apiary['name'],
                              },
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}