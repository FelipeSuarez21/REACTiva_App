import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final ScrollController _scrollController = ScrollController();
  final List<DocumentSnapshot> _logs = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMoreLogs = true;
  static const int _logsLimit = 20;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    _scrollController.addListener(_loadMoreLogs);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    if (_isLoading || !_hasMoreLogs) return;
    setState(() {
      _isLoading = true;
    });

    Query query = _firestore
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .limit(_logsLimit);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    try {
      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _lastDocument = snapshot.docs.last;
          _logs.addAll(snapshot.docs);
          if (snapshot.docs.length < _logsLimit) {
            _hasMoreLogs = false;
          }
        });
      } else {
        setState(() {
          _hasMoreLogs = false;
        });
      }
    } catch (e) {
      print('Error al cargar los movimientos: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadMoreLogs() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMoreLogs) {
      _fetchLogs();
    }
  }

  Future<void> _refreshLogs() async {
    setState(() {
      _logs.clear();
      _lastDocument = null;
      _hasMoreLogs = true;
    });
    await _fetchLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Últimos Movimientos'),
        backgroundColor: Colors.teal,
      ),
      body: _logs.isEmpty && _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshLogs,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _logs.length + (_hasMoreLogs ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _logs.length) {
                    final log = _logs[index].data() as Map<String, dynamic>;
                    final action = log['action'] ?? 'acción desconocida';
                    final userEmail = log['userEmail'] ?? 'Usuario desconocido';
                    final pieceName = log['pieceName'] ?? '';
                    final timestamp = log['timestamp'] as Timestamp?;
                    final date = timestamp != null ? timestamp.toDate() : null;

                    String formattedDate = date != null
                        ? DateFormat('dd/MM/yyyy HH:mm').format(date)
                        : 'Fecha desconocida';

                    bool showDateHeader = false;
                    if (index == 0) {
                      showDateHeader = true;
                    } else {
                      final prevTimestamp =
                          _logs[index - 1]['timestamp'] as Timestamp?;
                      final prevDate =
                          prevTimestamp != null ? prevTimestamp.toDate() : null;
                      if (_isNewDate(date, prevDate)) {
                        showDateHeader = true;
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDateHeader && date != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            child: Text(
                              DateFormat('dd MMM yyyy').format(date),
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ListTile(
                          leading: Icon(
                            _getActionIcon(action),
                            color: _getActionColor(action),
                          ),
                          title: Text(
                            _buildLogTitle(log),
                          ),
                          subtitle: Text(formattedDate),
                          trailing: Icon(Icons.chevron_right),
                          onTap: () {
                            _showActionDetails(context, log);
                          },
                        ),
                        Divider(),
                      ],
                    );
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
    );
  }

  String _buildLogTitle(Map<String, dynamic> log) {
    final action = log['action'] ?? 'acción desconocida';
    final userEmail = log['userEmail'] ?? 'Usuario desconocido';
    final pieceName = log['pieceName'] ?? '';
    final details = log['details'] as Map<String, dynamic>? ?? {};

    switch (action) {
      case 'register':
        return '$userEmail se ha registrado';
      case 'view':
        return '$userEmail visualizó "$pieceName"';
      case 'delete':
        return '$userEmail eliminó "$pieceName"';
      default:
        return '$userEmail ${_getActionText(action)} "$pieceName"';
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'create':
        return Icons.add_circle;
      case 'edit':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'view':
        return Icons.visibility;
      case 'download':
        return Icons.download;
      case 'status_change':
        return Icons.sync;
      case 'register':
        return Icons.person_add;
      default:
        return Icons.help;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'create':
        return Colors.green;
      case 'edit':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      case 'login':
        return Colors.purple;
      case 'logout':
        return Colors.orange;
      case 'view':
        return Colors.amber;
      case 'download':
        return Colors.indigo;
      case 'status_change':
        return Colors.cyan;
      case 'register':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getActionText(String action) {
    switch (action) {
      case 'create':
        return 'creó';
      case 'edit':
        return 'modificó';
      case 'delete':
        return 'eliminó';
      case 'login':
        return 'inició sesión en';
      case 'logout':
        return 'cerró sesión en';
      case 'view':
        return 'visualizó';
      case 'download':
        return 'descargó';
      case 'status_change':
        return 'cambió el estado de';
      case 'register':
        return 'se registró';
      default:
        return 'realizó una acción en';
    }
  }

  bool _isNewDate(DateTime? currentDate, DateTime? previousDate) {
    if (currentDate == null || previousDate == null) return false;
    return currentDate.day != previousDate.day ||
        currentDate.month != previousDate.month ||
        currentDate.year != previousDate.year;
  }

  void _showActionDetails(BuildContext context, Map<String, dynamic> log) {
    final action = log['action'] ?? 'acción desconocida';
    final userEmail = log['userEmail'] ?? 'Usuario desconocido';
    final pieceName = log['pieceName'] ?? '';
    final timestamp = log['timestamp'] as Timestamp?;
    final date = timestamp != null ? timestamp.toDate() : null;

    String formattedDate = date != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(date)
        : 'Fecha desconocida';

    final details = log['details'] as Map<String, dynamic>? ?? {};
    List<Widget> detailsWidgets = [];

    if (details.isNotEmpty) {
      details.forEach((key, value) {
        detailsWidgets.add(
          Text(
            '$key: $value',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
        );
      });
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detalles del Movimiento'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Acción: ${_getActionText(action)}'),
                SizedBox(height: 8),
                Text('Usuario: $userEmail'),
                SizedBox(height: 8),
                if (pieceName.isNotEmpty) Text('Elemento: $pieceName'),
                if (pieceName.isNotEmpty) SizedBox(height: 8),
                Text('Fecha: $formattedDate'),
                if (detailsWidgets.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text('Detalles:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  ...detailsWidgets,
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
