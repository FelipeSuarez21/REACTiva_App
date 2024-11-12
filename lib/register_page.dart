import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _fechaNacimientoController =
      TextEditingController();
  final TextEditingController _plantaController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _numEmpleadoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      String hashedPassword = _hashPassword(_passwordController.text);

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'nombres': _nombresController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'fechaNacimiento': _fechaNacimientoController.text.trim(),
        'planta': _plantaController.text.trim(),
        'area': _areaController.text.trim(),
        'numEmpleado': _numEmpleadoController.text.trim(),
        'email': _emailController.text.trim(),
        'password': hashedPassword,
        'role': 'user',
      });

      // Registrar la acción en la bitácora
      await _logRegisterAction(userCredential.user!.uid);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuario registrado exitosamente')),
      );

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => LoginPage(),
          transitionsBuilder: (context, animation1, animation2, child) {
            return FadeTransition(opacity: animation1, child: child);
          },
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error al registrar')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logRegisterAction(String userId) async {
    await _firestore.collection('logs').add({
      'action': 'register',
      'userId': userId,
      'userEmail': _emailController.text.trim(),
      'timestamp': Timestamp.now(),
      'details': {
        'nombres': _nombresController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'email': _emailController.text.trim(),
      },
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      setState(() {
        _fechaNacimientoController.text =
            DateFormat('yyyy-MM-dd').format(selectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(title: Text('Registrarse')),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.08,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: size.height * 0.02),
                Text(
                  'Crea tu cuenta',
                  style: TextStyle(
                    fontSize: size.width * 0.07,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                SizedBox(height: size.height * 0.04),
                _buildTextField(
                  controller: _nombresController,
                  label: 'Nombres',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese su nombre';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  controller: _apellidosController,
                  label: 'Apellidos',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese sus apellidos';
                    }
                    return null;
                  },
                ),
                _buildDateField(context),
                _buildDropdownField(
                  label: 'Planta',
                  items: [
                    'Planta Monterrey',
                    'Mina Monterrey',
                    'Planta Saltillo',
                    'Planta Tecomán',
                    'Planta Puebla',
                    'Planta San Luis Potosí'
                  ],
                  onChanged: (value) {
                    setState(() {
                      _plantaController.text = value!;
                    });
                  },
                ),
                _buildDropdownField(
                  label: 'Área',
                  items: [
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
                  onChanged: (value) {
                    setState(() {
                      _areaController.text = value!;
                    });
                  },
                ),
                _buildTextField(
                  controller: _numEmpleadoController,
                  label: 'Número de Empleado (5 dígitos)',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.length != 5) {
                      return 'El número de empleado debe tener 5 caracteres';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  controller: _emailController,
                  label: 'Correo Electrónico',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese un correo electrónico';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Ingrese un correo válido';
                    }
                    return null;
                  },
                ),
                _buildPasswordField(_passwordController, 'Contraseña'),
                _buildPasswordField(
                    _confirmPasswordController, 'Confirmar Contraseña'),
                SizedBox(height: size.height * 0.03),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.3,
                            vertical: size.height * 0.02,
                          ),
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child:
                            Text('Registrarse', style: TextStyle(fontSize: 16)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.teal[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String label,
  ) {
    return _buildTextField(
      controller: controller,
      label: label,
      keyboardType: TextInputType.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, ingrese su $label';
        }
        if (label == 'Confirmar Contraseña' &&
            value != _passwordController.text) {
          return 'Las contraseñas no coinciden';
        }
        return null;
      },
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: _fechaNacimientoController,
        decoration: InputDecoration(
          labelText: 'Fecha de Nacimiento',
          filled: true,
          fillColor: Colors.teal[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ),
        readOnly: true,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.teal[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, seleccione una opción';
          }
          return null;
        },
      ),
    );
  }
}
