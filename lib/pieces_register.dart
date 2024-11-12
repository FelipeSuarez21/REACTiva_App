import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:firebase_auth/firebase_auth.dart';

class AddPiecePage extends StatefulWidget {
  const AddPiecePage({super.key});

  @override
  _AddPiecePageState createState() => _AddPiecePageState();
}

class _AddPiecePageState extends State<AddPiecePage> {
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
  String? _selectedType;
  String? _selectedComponent;
  List<String> _components = [];
  final List<File> _selectedImages = [];
  bool _isLoading = false;

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
  }

  void _loadComponents() async {
    if (_selectedArea != null && _selectedType == 'subcomponent') {
      QuerySnapshot snapshot = await _firestore
          .collection('pieces')
          .where('type', isEqualTo: 'component')
          .where('area', isEqualTo: _selectedArea)
          .get();
      setState(() {
        _components =
            snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } else {
      setState(() {
        _components = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Pieza'),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(_nameController, 'Nombre de la Pieza'),
                _buildTextField(_codeController, 'Código'),
                _buildTextField(_modelController, 'Modelo'),
                _buildTextField(_brandController, 'Marca'),
                _buildTextField(_providerController, 'Proveedor'),
                _buildTextField(_descriptionController, 'Descripción',
                    maxLines: 3),
                _buildQuantityField(),
                _buildAreaDropdown(),
                _buildTypeDropdown(),
                if (_selectedType == 'subcomponent') _buildComponentDropdown(),
                _buildImagePicker(),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addPiece,
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: Colors.teal,
                    ),
                    child: Text(
                      'Registrar Pieza',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
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
          filled: true,
          fillColor: Colors.teal[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
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
          filled: true,
          fillColor: Colors.teal[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
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
            _loadComponents();
          });
        },
        decoration: InputDecoration(
          labelText: 'Área',
          filled: true,
          fillColor: Colors.teal[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _selectedType,
        items: ['component', 'subcomponent']
            .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedType = value;
            _loadComponents();
          });
        },
        decoration: InputDecoration(
          labelText: 'Tipo de pieza',
          filled: true,
          fillColor: Colors.teal[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildComponentDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _selectedComponent,
        items: _components
            .map((component) => DropdownMenuItem(
                  value: component,
                  child: Text(component),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedComponent = value;
          });
        },
        decoration: InputDecoration(
          labelText: 'Componente Padre',
          filled: true,
          fillColor: Colors.teal[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _selectedImages.map((image) {
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    image,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImages.remove(image);
                      });
                    },
                    child: Icon(
                      Icons.remove_circle,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: Icon(Icons.add_a_photo),
          label: Text('Agregar Imágenes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    setState(() {
      _selectedImages.addAll(pickedFiles.map((xfile) => File(xfile.path)));
    });
  }

  // Método para agregar la pieza
  Future<void> _addPiece() async {
    if (_nameController.text.isEmpty ||
        _codeController.text.isEmpty ||
        _selectedArea == null ||
        _quantityController.text.isEmpty ||
        _selectedType == null ||
        (_selectedType == 'subcomponent' && _selectedComponent == null)) {
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

    List<String> keywords = _generateKeywords(
      _nameController.text,
      _codeController.text,
    );

    try {
      setState(() {
        _isLoading = true;
      });

      List<String> imageUrls = [];
      for (File image in _selectedImages) {
        String? imageUrl = await _uploadImage(image);
        if (imageUrl != null) {
          imageUrls.add(imageUrl);
        }
      }

      DocumentReference newPieceDoc =
          await _firestore.collection('pieces').add({
        'name': _nameController.text,
        'code': _codeController.text,
        'model': _modelController.text,
        'brand': _brandController.text,
        'provider': _providerController.text,
        'description': _descriptionController.text,
        'area': _selectedArea,
        'quantity': quantity,
        'type': _selectedType,
        'parentComponent':
            _selectedType == 'subcomponent' ? _selectedComponent : null,
        'images': imageUrls,
        'keywords': keywords,
        'timestamp': FieldValue.serverTimestamp(),
      });

      User? currentUser = _auth.currentUser;

      await _firestore.collection('logs').add({
        'userId': currentUser?.uid ?? 'Unknown',
        'userEmail': currentUser?.email ?? 'Unknown',
        'action': 'create',
        'pieceId': newPieceDoc.id,
        'pieceName': _nameController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pieza registrada exitosamente')),
      );

      _clearForm();
    } catch (e) {
      print('Error al registrar la pieza: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar la pieza')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _codeController.clear();
    _modelController.clear();
    _brandController.clear();
    _providerController.clear();
    _descriptionController.clear();
    _quantityController.clear();
    setState(() {
      _selectedArea = null;
      _selectedType = null;
      _selectedComponent = null;
      _selectedImages.clear();
    });
  }

  List<String> _generateKeywords(String name, String code) {
    List<String> keywords = [];
    keywords.addAll(name.toLowerCase().split(' '));
    keywords.addAll(code.toLowerCase().split(' '));
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
