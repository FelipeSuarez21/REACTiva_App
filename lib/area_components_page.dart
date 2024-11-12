import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AreaComponentsPage extends StatelessWidget {
  final String area;
  final String? userRole;

  AreaComponentsPage({required this.area, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Componentes en $area'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('components')
            .where('area', isEqualTo: area)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          final components = snapshot.data!.docs;

          return ListView.builder(
            itemCount: components.length,
            itemBuilder: (context, index) {
              final component = components[index];
              return ListTile(
                title: Text(component['name']),
                subtitle: Text('Código: ${component['code']}'),
                trailing: userRole == 'admin'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              // Implementa la función de edición aquí
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              // Implementa la función de eliminación aquí
                            },
                          ),
                        ],
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
