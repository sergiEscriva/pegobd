import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/app_logger.dart';

/// Pantalla para visualizar los logs de errores de la aplicación
class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({Key? key}) : super(key: key);

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  final AppLogger _logger = AppLogger();
  String _logContent = '';
  bool _isLoading = true;
  double _logSize = 0.0;
  String? _logPath;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final content = await _logger.getLogContent();
      final size = await _logger.getLogSize();
      final path = _logger.getLogFilePath();

      setState(() {
        _logContent = content;
        _logSize = size;
        _logPath = path;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _logContent = 'Error cargando logs: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Limpiar Logs'),
            content: Text(
              '¿Estás seguro de que quieres eliminar todos los logs?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _logger.clearLog();
      _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('✅ Logs eliminados')));
      }
    }
  }

  Future<void> _shareLogs() async {
    if (_logPath != null) {
      try {
        await Share.shareXFiles([
          XFile(_logPath!),
        ], text: 'Logs de PegOBD - ${DateTime.now().toString()}');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error compartiendo logs: $e')),
          );
        }
      }
    }
  }

  Color _getColorForLogLevel(String line) {
    if (line.contains('[ERROR]') || line.contains('❌')) {
      return Colors.red;
    } else if (line.contains('[CRITICAL]') || line.contains('🚨')) {
      return Colors.red[900]!;
    } else if (line.contains('[WARNING]') || line.contains('⚠️')) {
      return Colors.orange;
    } else if (line.contains('[INFO]') || line.contains('ℹ️')) {
      return Colors.blue;
    } else if (line.contains('[DEBUG]') || line.contains('🔍')) {
      return Colors.grey;
    }
    return Colors.black87;
  }

  IconData _getIconForLogLevel(String line) {
    if (line.contains('[ERROR]') || line.contains('❌')) {
      return Icons.error;
    } else if (line.contains('[CRITICAL]') || line.contains('🚨')) {
      return Icons.crisis_alert;
    } else if (line.contains('[WARNING]') || line.contains('⚠️')) {
      return Icons.warning;
    } else if (line.contains('[INFO]') || line.contains('ℹ️')) {
      return Icons.info;
    } else if (line.contains('[DEBUG]') || line.contains('🔍')) {
      return Icons.bug_report;
    }
    return Icons.circle;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Registro de Errores'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Recargar',
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _shareLogs,
            tooltip: 'Compartir',
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _clearLogs,
            tooltip: 'Limpiar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Información del log
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    isDark
                        ? [Colors.blue[900]!, Colors.blue[700]!]
                        : [Colors.blue[100]!, Colors.blue[50]!],
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.blue[700]! : Colors.blue[200]!,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.description,
                  color: isDark ? Colors.blue[200] : Colors.blue[700],
                  size: 32,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Archivo de Logs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tamaño: ${_logSize.toStringAsFixed(2)} KB',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      if (_logPath != null)
                        Text(
                          _logPath!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.black45,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contenido del log
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _logContent.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.green,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No hay errores registrados',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '¡La aplicación funciona correctamente!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : Container(
                      color: isDark ? Colors.black : Colors.grey[50],
                      child: ListView.builder(
                        padding: EdgeInsets.all(8),
                        itemCount: _logContent.split('\n').length,
                        itemBuilder: (context, index) {
                          final lines = _logContent.split('\n');
                          if (index >= lines.length) return SizedBox.shrink();

                          final line = lines[index];
                          if (line.trim().isEmpty) return SizedBox.shrink();

                          final color = _getColorForLogLevel(line);
                          final icon = _getIconForLogLevel(line);

                          return Card(
                            margin: EdgeInsets.symmetric(
                              vertical: 2,
                              horizontal: 4,
                            ),
                            color: isDark ? Colors.grey[850] : Colors.white,
                            elevation: 1,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(icon, size: 16, color: color),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: SelectableText(
                                      line,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                        color: isDark ? Colors.white70 : color,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton:
          !_isLoading && _logContent.isNotEmpty
              ? FloatingActionButton.extended(
                onPressed: _loadLogs,
                icon: Icon(Icons.refresh),
                label: Text('Actualizar'),
              )
              : null,
    );
  }
}
