import 'package:beeconnect_flutter/screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:beeconnect_flutter/screens/home_screen.dart';
import 'package:beeconnect_flutter/screens/create_apiary.dart';
import 'package:beeconnect_flutter/screens/apiary_screen.dart';
import 'package:beeconnect_flutter/screens/create_hive.dart';

void main() {
  runApp(const BeeConnectApp());
}

class BeeConnectApp extends StatelessWidget {
  const BeeConnectApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeeConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.amber),
      initialRoute: '/home',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());

          case '/createApiary':
            return MaterialPageRoute(builder: (_) => const CreateApiaryScreen());

          case '/map_screen':
              return MaterialPageRoute(builder: (_) => const MapScreen());

          case '/apiaryScreen':
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => ApiaryScreen(
              apiaryId: args['apiaryId'],
              apiaryName: args['apiaryName'],
              latitude: args['latitude'],
              longitude: args['longitude'],
            ),
          );
          case '/createHive':
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => CreateHiveScreen(
              apiaryId: args['apiaryId'],
              apiaryName: args['apiaryName'],
            ),
          );

          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('Rota não encontrada')),
              ),
            );
        }
      },
    );
  }
}
