import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _userRole;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      setState(() {
        _userRole = userDoc['role'] ?? 'user';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('REACTiva',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false, // Quita la flecha de regreso
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _userRole == null
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.inventory,
                            label: 'Ver Inventario',
                            onTap: () {
                              Navigator.pushNamed(context, '/viewInventory');
                            },
                          ),
                          SizedBox(height: 16),
                          if (_userRole == 'admin') ...[
                            _buildMenuItem(
                              context: context,
                              icon: Icons.add_circle,
                              label: 'Dar de Alta una Pieza',
                              onTap: () {
                                Navigator.pushNamed(context, '/addPiece');
                              },
                            ),
                            SizedBox(height: 16),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.history,
                              label: 'Últimos Movimientos',
                              onTap: () {
                                Navigator.pushNamed(context, '/history');
                              },
                            ),
                            SizedBox(height: 16),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.admin_panel_settings,
                              label: 'Herramientas de Administrador',
                              onTap: () {
                                Navigator.pushNamed(context, '/admintools');
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Botón de cerrar sesión en la parte inferior
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacementNamed(context, '/login');
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al cerrar sesión')),
                        );
                      }
                    },
                    icon: Icon(Icons.logout),
                    label: Text('Cerrar sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 239, 55,
                          4), // Changed from 'primary' to 'backgroundColor'
                      padding: EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 24.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  )
                ],
              ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: Colors.teal.withOpacity(0.2),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 20.0),
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            SizedBox(width: 20.0),
            Icon(icon, size: 40, color: Colors.teal),
            SizedBox(width: 20.0),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
