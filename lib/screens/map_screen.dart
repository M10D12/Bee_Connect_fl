import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:beeconnect_flutter/db/database_helper.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final db = DatabaseHelper();
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _loadApiariesFromDb();
  }

  Future<void> _loadApiariesFromDb() async {
    try {
      final apiaries = await db.getApiaries();

      final markers = apiaries.map((apiary) {
        final lat = apiary['latitude'] ?? 0.0;
        final lng = apiary['longitude'] ?? 0.0;
        final name = apiary['name'] ?? '';

        return Marker(
        point: LatLng(lat, lng),
        width: 80,
        height: 80,
        child: Tooltip(
          message: name,
          child: const Icon(
            Icons.location_on,
            size: 40,
            color: Colors.redAccent,
          ),
        ),
      );

      }).toList();

      setState(() {
        _markers = markers;
      });
    } catch (e) {
      print('Erro ao carregar apiários do DB: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Apiários'),
        backgroundColor: const Color(0xFFFFC107),
      ),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(40.6405, -8.6538),
          zoom: 8.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.beeconnect',
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
    );
  }
}
