// main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import 'pieces_register.dart'; // Importa 'AddPiecePage'
import 'inventory_page.dart';
import 'piece_detail_page.dart';
import 'edit_piece_page.dart'; // Importa 'EditPiecePage'
import 'admin_tools_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'history_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REACTiva App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/register': (context) => RegisterPage(),
        '/forgotPassword': (context) => ForgotPasswordPage(),
        '/addPiece': (context) => AddPiecePage(), // Usa 'AddPiecePage'
        '/viewInventory': (context) => InventoryPage(),
        '/admintools': (context) => AdminToolsPage(),
        '/editPiece': (context) => EditPiecePage(), // Usa 'EditPiecePage'
        '/history': (context) => HistoryPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/pieceDetail') {
          final piece = settings.arguments as DocumentSnapshot?;
          if (piece == null) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(
                    child: Text('No se proporcionó información de la pieza')),
              ),
            );
          }
          return MaterialPageRoute(
            builder: (context) {
              return PieceDetailPage(piece: piece);
            },
          );
        }
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(child: Text('Página no encontrada')),
          ),
        );
      },
    );
  }
}
