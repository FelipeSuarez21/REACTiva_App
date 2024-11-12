import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminToolsPage extends StatefulWidget {
  const AdminToolsPage({super.key});

  @override
  _AdminToolsPageState createState() => _AdminToolsPageState();
}

class _AdminToolsPageState extends State<AdminToolsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<DocumentSnapshot> _users = [];
  bool _isLoading = true;
  String? _currentUserId;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      _userRole = userDoc['role'] ?? 'user';

      if (_userRole != 'admin') {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Acceso denegado')),
        );
      } else {
        _getUsers();
      }
    }
  }

  Future<void> _getUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      setState(() {
        _users = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al obtener usuarios: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserDetails(
    String userId,
    String nombres,
    String apellidos,
    String fechaNacimiento,
    String planta,
    String area,
    String numEmpleado,
    String email,
    String role,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'nombres': nombres,
        'apellidos': apellidos,
        'fechaNacimiento': fechaNacimiento,
        'planta': planta,
        'area': area,
        'numEmpleado': numEmpleado,
        'email': email,
        'role': role,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Información del usuario actualizada')),
      );
      _getUsers(); // Actualizar la lista de usuarios
    } catch (e) {
      print('Error al actualizar la información del usuario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la información')),
      );
    }
  }

  void _showEditUserDialog(DocumentSnapshot user) {
    final Map<String, dynamic> userData = user.data() as Map<String, dynamic>;
    final TextEditingController nombresController =
        TextEditingController(text: userData['nombres'] ?? '');
    final TextEditingController apellidosController =
        TextEditingController(text: userData['apellidos'] ?? '');
    final TextEditingController fechaNacimientoController =
        TextEditingController(text: userData['fechaNacimiento'] ?? '');
    final TextEditingController plantaController =
        TextEditingController(text: userData['planta'] ?? '');
    final TextEditingController areaController =
        TextEditingController(text: userData['area'] ?? '');
    final TextEditingController numEmpleadoController =
        TextEditingController(text: userData['numEmpleado'] ?? '');
    final TextEditingController emailController =
        TextEditingController(text: userData['email'] ?? '');
    String selectedRole = userData['role'] ?? 'user';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar Usuario'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(nombresController, 'Nombres'),
                _buildTextField(apellidosController, 'Apellidos'),
                _buildTextField(
                    fechaNacimientoController, 'Fecha de Nacimiento'),
                _buildDropdownField(
                  'Planta',
                  [
                    'Planta Monterrey',
                    'Mina Monterrey',
                    'Planta Saltillo',
                    'Planta Tecomán',
                    'Planta Puebla',
                    'Planta San Luis Potosí'
                  ],
                  plantaController,
                ),
                _buildDropdownField(
                  'Área',
                  [
                    'DUROCK',
                    'CTJ',
                    'BOARD',
                    'MANTENIMIENTO',
                    'LOGISTICA',
                    'METAL',
                    'OFICINAS',
                    'CALIDAD',
                    'No especifica'
                  ],
                  areaController,
                ),
                _buildTextField(numEmpleadoController, 'Número de Empleado'),
                _buildTextField(emailController, 'Correo Electrónico'),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: ['admin', 'user'].map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                  decoration: InputDecoration(labelText: 'Rol'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateUserDetails(
                  user.id,
                  nombresController.text,
                  apellidosController.text,
                  fechaNacimientoController.text,
                  plantaController.text,
                  areaController.text,
                  numEmpleadoController.text,
                  emailController.text,
                  selectedRole,
                );
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
      String label, List<String> items, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: DropdownButtonFormField<String>(
        value: controller.text.isEmpty ? null : controller.text,
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            controller.text = value!;
          });
        },
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Herramientas de Administrador'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(child: Text('No hay usuarios registrados'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot user = _users[index];
                      Map<String, dynamic> userData =
                          user.data() as Map<String, dynamic>;

                      String email = userData['email'] ?? 'Sin email';
                      String role = userData['role'] ?? 'user';
                      String nombres = userData['nombres'] ?? 'Sin nombre';
                      String apellidos =
                          userData['apellidos'] ?? 'Sin apellidos';
                      String userId = user.id;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 3,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.shade100,
                            child: Icon(
                              role == 'admin'
                                  ? Icons.admin_panel_settings
                                  : Icons.person,
                              color: Colors.teal.shade700,
                            ),
                          ),
                          title: Text(
                            '$nombres $apellidos',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade700,
                            ),
                          ),
                          subtitle: Text('Correo: $email\nRol: $role'),
                          trailing: userId != _currentUserId
                              ? IconButton(
                                  icon: Icon(Icons.edit, color: Colors.teal),
                                  onPressed: () {
                                    _showEditUserDialog(user);
                                  },
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
