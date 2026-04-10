import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  String get _userTasksCollection => 'users/${currentUser?.uid ?? ''}/tasks';

  Future<String> addTask(Task task) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated. Cannot sync tasks.');
    }
    try {
      DocumentReference docRef =
          await _firestore.collection(_userTasksCollection).add(task.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Add task to Firestore failed: $e');
    }
  }

  Future<void> updateTask(String docId, Task task) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated. Cannot update tasks.');
    }
    try {
      await _firestore
          .collection(_userTasksCollection)
          .doc(docId)
          .update(task.toJson());
    } catch (e) {
      throw Exception('Update task failed: $e');
    }
  }

  Stream<List<Task>> getUserTasks() {
    if (!isAuthenticated) {
      return Stream.error(
          Exception('User not authenticated. Cannot fetch tasks.'));
    }
    try {
      return _firestore
          .collection(_userTasksCollection)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        try {
          return snapshot.docs
              .map((doc) => Task.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
        } catch (e) {
          return [];
        }
      });
    } catch (e) {
      return Stream.error(Exception('Listen to tasks failed: $e'));
    }
  }

  Future<void> deleteTask(String docId) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated. Cannot delete tasks.');
    }
    try {
      await _firestore.collection(_userTasksCollection).doc(docId).delete();
    } catch (e) {
      throw Exception('Delete task failed: $e');
    }
  }
}
