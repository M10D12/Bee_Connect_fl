import 'package:flutter/material.dart';
import 'package:beeconnect_flutter/db/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = DatabaseHelper();
  late Future<List<Map<String, dynamic>>> _apiariesFuture;

  @override
  void initState() {
    super.initState();
    _refreshApiaries();
  }

  void _refreshApiaries() {
    setState(() {
      _apiariesFuture = db.getApiaries();
    });
  }

  void _deleteApiary(String id) async {
    await db.deleteApiary(id);
    _refreshApiaries();
  }

  @override
  Widget build(BuildContext context) {
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
              Navigator.pushNamed(context, '/apiaries');
              break;
            case 2:
              Navigator.pushNamed(context, '/myApiariesMap');
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/createApiary'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('+ Apiário'),
            ),
            const SizedBox(height: 16),
            Expanded(
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
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteApiary(apiary['id']),
                          ),
                          onTap: () => Navigator.pushNamed(context, '/apiaryScreen'),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
