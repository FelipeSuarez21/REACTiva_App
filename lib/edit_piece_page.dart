import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:firebase_auth/firebase_auth.dart';

class EditPiecePage extends StatefulWidget {
  const EditPiecePage({super.key});

  @override
  _EditPiecePageState createState() => _EditPiecePageState();
}

class _EditPiecePageState extends State<EditPiecePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _providerController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  String? _selectedArea;
  List<dynamic> _imageUrls = [];
  final List<File> _newImages = [];

  DocumentSnapshot? piece;
  String? _userRole;
  bool _isLoading = true;

  final List<String> _areas = [
    'Board',
    'Molino Williams',
    'Pfeiffer',
    'Colector de polvos',
    'Mezclador',
  ];

  @override
  void initState() {
    super.initState();
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
        setState(() {
          _isLoading = false;
        });
        _loadPieceData();
      }
    }
  }

  void _loadPieceData() {
    piece = ModalRoute.of(context)!.settings.arguments as DocumentSnapshot?;
    if (piece != null) {
      _nameController.text = piece!['name'] ?? '';
      _codeController.text = piece!['code'] ?? '';
      _modelController.text = piece!['model'] ?? '';
      _brandController.text = piece!['brand'] ?? '';
      _providerController.text = piece!['provider'] ?? '';
      _descriptionController.text = piece!['description'] ?? '';
      _quantityController.text = piece!['quantity']?.toString() ?? '';
      _selectedArea = piece!['area'];
      _imageUrls = piece!['images'] ?? [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _modelController.dispose();
    _brandController.dispose();
    _providerController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Cargando...'),
          backgroundColor: Colors.teal,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Pieza'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(_nameController, 'Nombre de la Pieza'),
            _buildTextField(_codeController, 'Código'),
            _buildTextField(_modelController, 'Modelo'),
            _buildTextField(_brandController, 'Marca'),
            _buildTextField(_providerController, 'Proveedor'),
            _buildTextField(_descriptionController, 'Descripción', maxLines: 3),
            _buildQuantityField(),
            _buildAreaDropdown(),
            _buildImagePicker(),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updatePiece,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
              child: Text('Actualizar Pieza'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildQuantityField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: _quantityController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Cantidad',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildAreaDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _selectedArea,
        items: _areas
            .map((area) => DropdownMenuItem(
                  value: area,
                  child: Text(area),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedArea = value;
          });
        },
        decoration: InputDecoration(
          labelText: 'Área',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            ..._imageUrls.map((imageUrl) => Stack(
                  children: [
                    Image.network(
                      imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _imageUrls.remove(imageUrl);
                          });
                        },
                        child: Icon(
                          Icons.close,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                )),
            ..._newImages.map((image) => Stack(
                  children: [
                    Image.file(
                      image,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _newImages.remove(image);
                          });
                        },
                        child: Icon(
                          Icons.close,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                )),
          ],
        ),
        SizedBox(height: 8.0),
        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: Icon(Icons.add_a_photo),
          label: Text('Agregar Imágenes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    setState(() {
      _newImages.addAll(pickedFiles.map((xfile) => File(xfile.path)));
    });
  }

  Future<void> logEditAction(
      Map<String, dynamic> oldData, Map<String, dynamic> newData) async {
    User? currentUser = _auth.currentUser;
    final modifiedFields = <String, dynamic>{};

    oldData.forEach((key, value) {
      if (newData[key] != value) {
        modifiedFields[key] = {'old': value, 'new': newData[key]};
      }
    });

    await _firestore.collection('logs').add({
      'userId': currentUser?.uid ?? 'Unknown',
      'userEmail': currentUser?.email ?? 'Unknown',
      'action': 'edit',
      'pieceId': piece!.id,
      'pieceName': newData['name'],
      'changes': modifiedFields,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updatePiece() async {
    if (_nameController.text.isEmpty ||
        _codeController.text.isEmpty ||
        _selectedArea == null ||
        _quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Por favor complete todos los campos obligatorios')),
      );
      return;
    }

    int? quantity = int.tryParse(_quantityController.text);
    if (quantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ingrese una cantidad válida')),
      );
      return;
    }

    List<String> keywords =
        _generateKeywords(_nameController.text, _codeController.text);

    try {
      List<String> newImageUrls = [];
      for (File image in _newImages) {
        String? imageUrl = await _uploadImage(image);
        if (imageUrl != null) {
          newImageUrls.add(imageUrl);
        }
      }

      List<String> allImageUrls = [
        ..._imageUrls.cast<String>(),
        ...newImageUrls
      ];

      Map<String, dynamic> newData = {
        'name': _nameController.text,
        'code': _codeController.text,
        'model': _modelController.text,
        'brand': _brandController.text,
        'provider': _providerController.text,
        'description': _descriptionController.text,
        'area': _selectedArea,
        'quantity': quantity,
        'images': allImageUrls,
        'keywords': keywords,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('pieces').doc(piece!.id).update(newData);
      await logEditAction(piece!.data() as Map<String, dynamic>, newData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pieza actualizada exitosamente')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error al actualizar la pieza: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la pieza')),
      );
    }
  }

  List<String> _generateKeywords(String name, String code) {
    List<String> keywords = [];
    keywords.add(name.toLowerCase());
    keywords.add(code.toLowerCase());
    keywords.addAll(name.toLowerCase().split(' '));
    return keywords;
  }

  Future<String?> _uploadImage(File image) async {
    try {
      String fileName = p.basename(image.path);
      Reference ref = _storage.ref().child('piece_images/$fileName');
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error al subir la imagen: $e');
      return null;
    }
  }
}
