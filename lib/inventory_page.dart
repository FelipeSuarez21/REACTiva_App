import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _userRole;
  bool _isLoading = true;

  final List<DocumentSnapshot> _allPieces = [];

  @override
  void initState() {
    super.initState();
    _getUserRole();
    _getAllPieces();
  }

  Future<void> _getUserRole() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      setState(() {
        _userRole = userDoc['role'] ?? 'user';
      });
    }
  }

  Future<void> _getAllPieces() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection('pieces').orderBy('timestamp').get();

      setState(() {
        _allPieces.addAll(snapshot.docs);
        _isLoading = false;
      });
    } catch (e) {
      print('Error al obtener piezas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, List<DocumentSnapshot>> _groupComponentsByArea(
      List<DocumentSnapshot> documents) {
    Map<String, List<DocumentSnapshot>> componentsByArea = {};
    for (var doc in documents) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      String area = data['area'] ?? 'Sin área';
      String type = data['type'] ?? 'component';

      if (type == 'component') {
        componentsByArea.putIfAbsent(area, () => []).add(doc);
      }
    }
    return componentsByArea;
  }

  Future<void> _refreshList() async {
    setState(() {
      _allPieces.clear();
      _isLoading = true;
    });
    await _getAllPieces();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<DocumentSnapshot>> componentsByArea =
        _groupComponentsByArea(_allPieces);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshList,
              child: ListView.builder(
                itemCount: componentsByArea.length,
                itemBuilder: (context, index) {
                  String area = componentsByArea.keys.elementAt(index);
                  List<DocumentSnapshot> components = componentsByArea[area]!;

                  return _buildAreaCard(area, components);
                },
              ),
            ),
    );
  }

  Widget _buildAreaCard(String area, List<DocumentSnapshot> components) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      elevation: 3,
      child: ExpansionTile(
        leading: const Icon(Icons.location_on, color: Colors.teal),
        title: Text(
          '$area (${components.length} componentes)',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
        children: components.map((component) {
          return _buildComponentCard(component);
        }).toList(),
      ),
    );
  }

  Widget _buildComponentCard(DocumentSnapshot component) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
      elevation: 2,
      child: ExpansionTile(
        leading: const Icon(Icons.memory, color: Colors.teal),
        title: Text(
          component['name'] ?? 'Sin nombre',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        children: [
          _buildComponentDetail(component),
          _buildSubcomponents(component),
        ],
      ),
    );
  }

  Widget _buildComponentDetail(DocumentSnapshot component) {
    return ListTile(
      title: const Text("Ver detalles del componente"),
      trailing: _buildActions(component),
      onTap: () {
        _logViewAction(component);
        Navigator.pushNamed(
          context,
          '/pieceDetail',
          arguments: component,
        );
      },
    );
  }

  Widget _buildSubcomponents(DocumentSnapshot component) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('pieces')
          .where('parentComponent', isEqualTo: component['name'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final subcomponents = snapshot.data!.docs;

        if (subcomponents.isEmpty) {
          return const ListTile(
            title: Text('No hay subcomponentes.'),
          );
        }

        return ExpansionTile(
          leading: const Icon(Icons.build, color: Colors.teal),
          title: Text("Subcomponentes (${subcomponents.length})"),
          children: subcomponents.map((subcomponent) {
            return ListTile(
              leading: const Icon(Icons.chevron_right),
              title: Text(subcomponent['name'] ?? 'Sin nombre'),
              subtitle: Text('Código: ${subcomponent['code'] ?? 'N/A'}'),
              trailing:
                  _userRole == 'admin' ? _buildActions(subcomponent) : null,
              onTap: () {
                _logViewAction(subcomponent);
                Navigator.pushNamed(
                  context,
                  '/pieceDetail',
                  arguments: subcomponent,
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActions(DocumentSnapshot piece) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'Editar') {
          _navigateToEditPiece(piece);
        } else if (value == 'Eliminar') {
          _confirmDelete(piece);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'Editar',
          child: Text('Editar'),
        ),
        const PopupMenuItem(
          value: 'Eliminar',
          child: Text('Eliminar'),
        ),
      ],
    );
  }

  void _navigateToEditPiece(DocumentSnapshot piece) {
    Navigator.pushNamed(
      context,
      '/editPiece',
      arguments: piece,
    ).then((_) {
      _refreshList();
    });
  }

  void _confirmDelete(DocumentSnapshot piece) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Pieza'),
        content: const Text('¿Está seguro de que desea eliminar esta pieza?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePiece(piece);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePiece(DocumentSnapshot piece) async {
    try {
      await _firestore.collection('pieces').doc(piece.id).delete();
      await _logDeleteAction(piece);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pieza eliminada exitosamente')),
      );
      _refreshList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Error al eliminar la pieza. No tiene permisos o contacte a soporte.')),
      );
    }
  }

  Future<void> _logViewAction(DocumentSnapshot piece) async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection('logs').add({
        'action': 'view',
        'userEmail': currentUser.email,
        'pieceName': piece['name'] ?? 'Sin nombre',
        'timestamp': Timestamp.now(),
      });
    }
  }

  Future<void> _logDeleteAction(DocumentSnapshot piece) async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection('logs').add({
        'action': 'delete',
        'userEmail': currentUser.email,
        'pieceName': piece['name'] ?? 'Sin nombre',
        'timestamp': Timestamp.now(),
      });
    }
  }
}
