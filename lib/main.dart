import 'package:flutter/material.dart';
import 'package:beeconnect_flutter/screens/home_screen.dart';
// import 'package:beeconnect_flutter/screens/login_screen.dart';
// import 'package:beeconnect_flutter/screens/register_screen.dart';
import 'package:beeconnect_flutter/screens/create_apiary.dart';
// import 'package:beeconnect_flutter/screens/edit_hive_screen.dart';
// import 'package:beeconnect_flutter/screens/apiary_screen.dart';
// import 'package:beeconnect_flutter/screens/my_apiaries_map_screen.dart';
// import 'package:beeconnect_flutter/screens/colmeia_screen.dart';
// import 'package:beeconnect_flutter/screens/profile_screen.dart';
// import 'package:beeconnect_flutter/screens/apiary_selection_screen.dart';
// import 'package:beeconnect_flutter/screens/statistics_screen.dart';
// import 'package:beeconnect_flutter/screens/calendar_screen.dart';

void main() {
  runApp(BeeConnectApp());
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
      routes: {
        // '/login': (context) => LoginScreen(),
        // '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/createApiary': (context) => CreateApiaryScreen(),
        // '/editHive': (context) => EditHiveScreen(),
        // '/apiaryScreen': (context) => ApiaryScreen(),
        // '/myApiariesMap': (context) => MyApiariesMapScreen(),
        // '/colmeiaScreen': (context) => ColmeiaScreen(),
        // '/profile': (context) => ProfileScreen(),
        // '/apiaries': (context) => ApiarySelectionScreen(),
        // '/statistics': (context) => StatisticsScreen(),
        // '/calendar': (context) => CalendarScreen(),
      },
    );
  }
}
