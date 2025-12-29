import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _connectionController.stream;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  // Inizializza il monitoraggio della connessione
  void initialize() {
    _checkInitialConnection();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  // Controlla connessione iniziale
  Future<void> _checkInitialConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      _isOnline = false;
      _connectionController.add(false);
    }
  }

  // Aggiorna stato connessione
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Se almeno uno dei risultati è diverso da none, siamo online
    final wasOnline = _isOnline;
    _isOnline = results.any((result) => result != ConnectivityResult.none);
    
    // Notifica solo se lo stato è cambiato
    if (wasOnline != _isOnline) {
      _connectionController.add(_isOnline);
    }
  }

  // Controlla connessione manualmente
  Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = results.any((result) => result != ConnectivityResult.none);
      return _isOnline;
    } catch (e) {
      _isOnline = false;
      return false;
    }
  }

  // Chiudi stream
  void dispose() {
    _connectionController.close();
  }
}
