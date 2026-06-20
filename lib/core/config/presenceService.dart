import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<void> initialize() async {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await _updatePresence(true);
        _setupPresenceListener(user.uid);
      }
    });
  }

  void _setupPresenceListener(String userId) {
    _database.child('onlineStatus/$userId').onDisconnect().set(false);
  }

  Future<void> _updatePresence(bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final updates = {
      'isOnline': isOnline,
      'lastSeen': ServerValue.timestamp,
    };

    await _database.child('onlineStatus/${user.uid}').set(isOnline);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update(updates);
  }

  Future<void> setOnline() async => await _updatePresence(true);
  Future<void> setOffline() async => await _updatePresence(false);

  Stream<bool> getUserPresence(String userId) {
    return _database.child('onlineStatus/$userId').onValue.map((event) {
      return event.snapshot.value as bool? ?? false;
    });
  }
}