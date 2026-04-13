import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../services/local_db_service.dart';
import '../services/firestore_service.dart';

import 'service_providers.dart';
import 'connectivity_provider.dart';

final taskProvider = StateNotifierProvider<TaskNotifier, AsyncValue<List<Task>>>((ref) {
  final localDb = ref.watch(localDbServiceProvider);
  final firestore = ref.watch(firestoreServiceProvider);
  final isOnlineAsync = ref.watch(connectivityProvider);
  final isOnline = isOnlineAsync.valueOrNull ?? false;
  return TaskNotifier(localDb, firestore, ref, isOnline);
});

class TaskNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  final LocalDbService localDb;
  final FirestoreService firestore;
  final Ref ref;
  bool connectivity;
  bool _initialized = false;
  bool _syncing = false;

  TaskNotifier(this.localDb, this.firestore, this.ref, this.connectivity) : super(const AsyncLoading()) {
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    
    // Initial load
    await _loadTasks();
    
    // Listen for connectivity changes
    ref.listen(connectivityProvider.select((state) => state.valueOrNull ?? false), (prev, isOnline) {
      connectivity = isOnline;
      if (isOnline && !_syncing) {
        syncTasks();
      }
    });
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    if (state is! AsyncLoading) state = const AsyncLoading();
    try {
      List<Task> localTasks = await localDb.getAllLocalTasks();
      if (!mounted) return;
      state = AsyncData(localTasks);
    } catch (e) {
      if (!mounted) return;
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> addDraftTask(Task task) async {
    try {
      final id = await localDb.insertDraft(task);
      final updatedTask = task.copyWith(id: id);
      
      // Optimistically update UI
      final currentData = state.valueOrNull ?? [];
      state = AsyncData([...currentData, updatedTask]);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> syncTasks() async {
    if (!connectivity) {
      state = AsyncError(Exception('No internet connection'), StackTrace.current);
      return;
    }
    if (_syncing) return;
    
    _syncing = true;
    try {
      List<Task> drafts = await localDb.getUnsyncedDrafts();
      
      for (Task draft in drafts) {
        if (draft.id != null) {
          await firestore.addTask(draft);
          await localDb.markSynced(draft.id!);
        }
      }
      
      // Reload after successful sync
      await _loadTasks();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    } finally {
      _syncing = false;
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      if (task.id != null) {
        await localDb.updateTaskStatus(task.id!, task.status);
      }
      // Optimistically update UI
      final currentData = state.valueOrNull ?? [];
      state = AsyncData(
        currentData.map((t) => t.id == task.id ? task : t).toList(),
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> deleteLocalTask(int id) async {
    try {
      await localDb.deleteTask(id);
      // Optimistically update UI
      final currentData = state.valueOrNull ?? [];
      state = AsyncData(currentData.where((t) => t.id != id).toList());
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}
