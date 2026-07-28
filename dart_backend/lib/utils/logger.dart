import 'dart:io';

class AppLogger {
  static final File _logFile = File('logs/server.log');

  static void init() {
    if (!_logFile.parent.existsSync()) {
      _logFile.parent.createSync(recursive: true);
    }
  }

  static void info(String message) {
    _log('INFO', message);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log('ERROR', '$message ${error != null ? '\n$error' : ''} ${stackTrace != null ? '\n$stackTrace' : ''}');
  }

  static void _log(String level, String message) {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final logLine = '[$timestamp] [$level] $message';
    
    // Print to console
    print(logLine);
    
    // Append to file
    try {
      _logFile.writeAsStringSync('$logLine\n', mode: FileMode.append);
    } catch (e) {
      print('Failed to write to log file: $e');
    }
  }
}
