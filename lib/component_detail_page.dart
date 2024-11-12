import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ComponentDetailPage extends StatefulWidget {
  final DocumentSnapshot component;
  final String? userRole;

  const ComponentDetailPage({Key? key, required this.component, this.userRole})
      : super(key: key);

  @override
  _ComponentDetailPageState createState() => _ComponentDetailPageState();
}

class _ComponentDetailPageState extends State<ComponentDetailPage> {
  @override
  Widget build(BuildContext context) {
    final componentData =
        widget.component.data() as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(componentData['name'] ?? 'Detalle del Componente'),
        backgroundColor: Colors.teal,
        actions: widget.userRole == 'admin'
            ? [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _navigateToEditComponent(widget.component);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _confirmDeleteComponent(widget.component);
                  },
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildComponentDetails(componentData),
            const SizedBox(height: 16),
            _buildSubcomponentsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentDetails(Map<String, dynamic> componentData) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal,
          child: Icon(Icons.memory, color: Colors.white),
        ),
        title: Text(
          componentData['name'] ?? 'Sin nombre',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Código: ${componentData['code'] ?? 'N/A'}',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildSubcomponentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pieces')
          .where('parentComponent', isEqualTo: widget.component['name'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar subcomponentes'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final subcomponents = snapshot.data!.docs;

        if (subcomponents.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('No hay subcomponentes asociados a este componente.'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: subcomponents.length,
          itemBuilder: (context, index) {
            final subcomponentData =
                subcomponents[index].data() as Map<String, dynamic>? ?? {};

            return Card(
              margin:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade200,
                  child: Icon(Icons.build, color: Colors.white),
                ),
                title: Text(
                  subcomponentData['name'] ?? 'Sin nombre',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Código: ${subcomponentData['code'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 16),
                ),
                trailing: widget.userRole == 'admin'
                    ? PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'Editar') {
                            _navigateToEditSubcomponent(subcomponents[index]);
                          } else if (value == 'Eliminar') {
                            _confirmDeleteSubcomponent(subcomponents[index]);
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
                      )
                    : null,
                onTap: () {
                  // Navegar a los detalles del subcomponente si es necesario
                  _navigateToSubcomponentDetail(subcomponents[index]);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToEditComponent(DocumentSnapshot component) {
    Navigator.pushNamed(
      context,
      '/editComponent',
      arguments: component,
    ).then((_) {
      setState(() {});
    });
  }

  void _confirmDeleteComponent(DocumentSnapshot component) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Componente'),
        content: Text('¿Estás seguro de que deseas eliminar este componente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComponent(component);
            },
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _deleteComponent(DocumentSnapshot component) async {
    try {
      await FirebaseFirestore.instance
          .collection('pieces')
          .doc(component.id)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Componente eliminado exitosamente')),
      );
      Navigator.pop(context); // Regresar a la pantalla anterior
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el componente')),
      );
    }
  }

  void _navigateToEditSubcomponent(DocumentSnapshot subcomponent) {
    Navigator.pushNamed(
      context,
      '/editSubcomponent',
      arguments: subcomponent,
    ).then((_) {
      setState(() {});
    });
  }

  void _confirmDeleteSubcomponent(DocumentSnapshot subcomponent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Subcomponente'),
        content:
            Text('¿Estás seguro de que deseas eliminar este subcomponente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSubcomponent(subcomponent);
            },
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _deleteSubcomponent(DocumentSnapshot subcomponent) async {
    try {
      await FirebaseFirestore.instance
          .collection('pieces')
          .doc(subcomponent.id)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subcomponente eliminado exitosamente')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el subcomponente')),
      );
    }
  }

  void _navigateToSubcomponentDetail(DocumentSnapshot subcomponent) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SubcomponentDetailPage(subcomponent: subcomponent),
      ),
    );
  }
}

class SubcomponentDetailPage extends StatelessWidget {
  final DocumentSnapshot subcomponent;

  const SubcomponentDetailPage({Key? key, required this.subcomponent})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subcomponentData = subcomponent.data() as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(subcomponentData['name'] ?? 'Detalle del Subcomponente'),
        backgroundColor: Colors.teal,
      ),
      body: Card(
        margin: const EdgeInsets.all(16.0),
        elevation: 4,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.teal.shade200,
            child: Icon(Icons.build, color: Colors.white),
          ),
          title: Text(
            subcomponentData['name'] ?? 'Sin nombre',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Código: ${subcomponentData['code'] ?? 'N/A'}',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
