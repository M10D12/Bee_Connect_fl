import 'package:beeconnect_flutter/screens/map_screen.dart';
import 'package:beeconnect_flutter/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:beeconnect_flutter/screens/home_screen.dart';
import 'package:beeconnect_flutter/screens/create_apiary.dart';
import 'package:beeconnect_flutter/screens/apiary_screen.dart';
import 'package:beeconnect_flutter/screens/login.dart';
import 'package:beeconnect_flutter/screens/register.dart';
import 'package:beeconnect_flutter/screens/create_hive.dart';
import 'package:beeconnect_flutter/screens/hive_screen.dart';  // <-- IMPORTA TAMBÉM!
import 'package:beeconnect_flutter/screens/statistics.dart';
import 'package:beeconnect_flutter/screens/select_apiary_stats.dart';
import 'package:beeconnect_flutter/screens/calendar.dart';

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
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());

          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());

          case '/createApiary':
            return MaterialPageRoute(builder: (_) => const CreateApiaryScreen());

          case '/login':
            return MaterialPageRoute(builder: (_) => LoginPage());

          case '/map_screen':
            return MaterialPageRoute(builder: (_) => const MapScreen());

          case '/register':
            return MaterialPageRoute(builder: (_) => RegisterPage());

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

          case '/hiveScreen':  // <=== NOVO CASO ADICIONADO
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => HiveScreen(
                hiveId: args['hiveId'],
              ),
            );

          case '/statistics':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => StatisticsScreen(
                apiaryId: args['apiaryId'],
                apiaryName: args['apiaryName'],
              ),
            );

          case '/select_apiary_stats':
            return MaterialPageRoute(builder: (_) => const SelectApiaryForStatisticsScreen());

          case '/calendar':
            return MaterialPageRoute(builder: (_) => const CalendarScreen());

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
