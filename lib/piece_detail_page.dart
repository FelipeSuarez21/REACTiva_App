import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PieceDetailPage extends StatelessWidget {
  final DocumentSnapshot piece;

  const PieceDetailPage({Key? key, required this.piece}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> pieceData =
        piece.data() as Map<String, dynamic>? ?? {};
    final images = List<String>.from(pieceData['images'] ?? []);
    final isComponent =
        pieceData.containsKey('type') && pieceData['type'] == 'component';

    return Scaffold(
      appBar: AppBar(
        title: Text(pieceData['name'] ?? 'Detalle de Pieza'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildImageCarousel(images),
            const SizedBox(height: 16),
            _buildDetailsCard(pieceData),
            const SizedBox(height: 16),
            if (isComponent) _buildSubcomponentsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    return images.isNotEmpty
        ? SizedBox(
            height: 250,
            child: PageView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Image.network(
                  images[index],
                  fit: BoxFit.cover,
                );
              },
            ),
          )
        : Container(
            height: 200,
            color: Colors.grey[200],
            child: Icon(Icons.image_not_supported, size: 100),
          );
  }

  Widget _buildDetailsCard(Map<String, dynamic> pieceData) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.code, 'Código', pieceData['code']),
            _buildDetailRow(Icons.label, 'Modelo', pieceData['model']),
            _buildDetailRow(
                Icons.branding_watermark, 'Marca', pieceData['brand']),
            _buildDetailRow(Icons.person, 'Proveedor', pieceData['provider']),
            _buildDetailRow(Icons.location_on, 'Área', pieceData['area']),
            _buildDetailRow(Icons.format_list_numbered, 'Cantidad',
                pieceData['quantity']?.toString() ?? 'N/A'),
            _buildDetailRow(
                Icons.description, 'Descripción', pieceData['description']),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(value ?? 'N/A'),
    );
  }

  Widget _buildSubcomponentsList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pieces')
          .where('parentComponent', isEqualTo: piece['name'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar subcomponentes'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No hay subcomponentes para este componente.'),
          );
        }

        final subcomponents = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Subcomponentes:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              itemCount: subcomponents.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final subcomponentData =
                    subcomponents[index].data() as Map<String, dynamic>? ?? {};
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 4.0),
                  child: ListTile(
                    leading: const Icon(Icons.build, color: Colors.teal),
                    title: Text(subcomponentData['name'] ?? 'Sin nombre'),
                    subtitle:
                        Text('Código: ${subcomponentData['code'] ?? 'N/A'}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PieceDetailPage(
                            piece: subcomponents[index],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
