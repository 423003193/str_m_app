import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/service_providers.dart';
import '../services/api_service.dart';
import '../models/task.dart';
import '../models/weather.dart';
import 'task_detail_screen.dart';

// ═══════════════════════════════════════════════
// Custom Slide-Up Page Route
// ═══════════════════════════════════════════════
class _SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  _SlideUpRoute({required this.page})
      : super(
          pageBuilder: (context, anim, secondaryAnim) => page,
          transitionsBuilder: (context, anim, secondaryAnim, child) {
            final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(curve),
              child: FadeTransition(opacity: curve, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        );
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSyncing = false;
  int _currentTab = 0;

  // Animations
  late AnimationController _fabController;
  late AnimationController _headerController;
  late AnimationController _statsController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Stagger entrance
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _statsController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fabController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final tasksAsync = ref.watch(taskProvider);
    final connectivityAsync = ref.watch(connectivityProvider);
    final isOnline = connectivityAsync.valueOrNull ?? false;

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentTab,
          children: [
            _buildDashboard(user, tasksAsync, isOnline),
            _buildLiveDataTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          border: Border(top: BorderSide(color: AppColors.violet.withValues(alpha: 0.08))),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppColors.hotPink.withValues(alpha: 0.15),
          selectedIndex: _currentTab,
          onDestinationSelected: (i) {
            HapticFeedback.lightImpact();
            setState(() => _currentTab = i);
          },
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.hotPink),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.insights_rounded, color: AppColors.hotPink),
              label: 'Live Data',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentTab == 0
          ? ScaleTransition(
              scale: CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
              child: FloatingActionButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showAddTaskDialog();
                },
                child: const Icon(Icons.add_rounded),
              ),
            )
          : null,
    );
  }

  // ────────────────────────────────────────────
  // DASHBOARD
  // ────────────────────────────────────────────
  Widget _buildDashboard(dynamic user, AsyncValue<List<Task>> tasksAsync, bool isOnline) {
    return tasksAsync.when(
      data: (tasks) {
        final pending = tasks.where((t) => t.status != 'done').toList();
        final completed = tasks.where((t) => t.status == 'done').toList();
        final progress = tasks.isEmpty ? 0.0 : completed.length / tasks.length;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
                    .animate(CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic)),
                child: FadeTransition(
                  opacity: _headerController,
                  child: _buildHeader(user, isOnline),
                ),
              ),
            ),
            // ── Stats ──
            SliverToBoxAdapter(
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
                    .animate(CurvedAnimation(parent: _statsController, curve: Curves.easeOutCubic)),
                child: FadeTransition(
                  opacity: _statsController,
                  child: _buildStatsRow(tasks.length, pending.length, completed.length, progress),
                ),
              ),
            ),
            // ── Offline ──
            if (!isOnline)
              SliverToBoxAdapter(child: _buildOfflineBanner()),
            // ── Pending ──
            if (pending.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: _buildSectionHeader('Pending', pending.length),
                ),
              ),
            if (pending.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _AnimatedTaskEntry(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildTaskCard(pending[i]),
                    ),
                  ),
                  childCount: pending.length,
                ),
              ),
            // ── Completed ──
            if (completed.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: _buildSectionHeader('Completed', completed.length),
                ),
              ),
            if (completed.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _AnimatedTaskEntry(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildTaskCard(completed[i]),
                    ),
                  ),
                  childCount: completed.length,
                ),
              ),
            // ── Empty ──
            if (tasks.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
      loading: () => _buildShimmerLoading(),
      error: (e, st) => _buildErrorState(e),
    );
  }

  // ── Header ──
  Widget _buildHeader(dynamic user, bool isOnline) {
    final email = user?.email ?? 'User';
    final name = email.contains('@') ? email.split('@').first : email;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $name',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Here\'s your task overview',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Row(
            children: [
              // Animated Sync Button
              _AnimatedPressButton(
                onPressed: _isSyncing || !isOnline
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _isSyncing = true);
                        HapticFeedback.lightImpact();
                        try {
                          await ref.read(taskProvider.notifier).syncTasks();
                          messenger.showSnackBar(
                            SnackBar(
                              content: const Text('Synced!'),
                              backgroundColor: AppColors.mint.withValues(alpha: 0.9),
                            ),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Sync failed: $e'),
                              backgroundColor: AppColors.hotPink.withValues(alpha: 0.9),
                            ),
                          );
                        } finally {
                          if (mounted) setState(() => _isSyncing = false);
                        }
                      },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cardDark,
                    border: Border.all(color: AppColors.violet.withValues(alpha: 0.15)),
                  ),
                  child: _isSyncing
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.hotPink),
                        )
                      : Icon(
                          Icons.sync_rounded,
                          color: isOnline ? AppColors.softLavender : AppColors.textSecondary.withValues(alpha: 0.3),
                          size: 20,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              // Profile Avatar
              _AnimatedPressButton(
                onPressed: _showLogoutDialog,
                child: Hero(
                  tag: 'profile_avatar',
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [AppColors.hotPink, AppColors.violet]),
                    ),
                    child: Center(
                      child: Text(
                        name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats with Animated Progress ──
  Widget _buildStatsRow(int total, int pending, int completed, double progress) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          // Animated Progress Ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return SizedBox(
                width: 72,
                height: 72,
                child: CustomPaint(
                  painter: _ProgressRingPainter(value),
                  child: Center(
                    child: Text(
                      '${(value * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAnimatedStat('Total', total, [AppColors.softLavender, AppColors.violet]),
                _buildAnimatedStat('Pending', pending, [AppColors.hotPink, AppColors.violet]),
                _buildAnimatedStat('Done', completed, [AppColors.mint, AppColors.mint]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStat(String label, int count, List<Color> colors) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: count),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(colors: colors).createShader(bounds),
              child: Text(
                value.toString(),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ],
        );
      },
    );
  }

  // ── Offline Banner ──
  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.orange[300], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You\'re offline. Tasks will sync when you reconnect.',
              style: TextStyle(color: Colors.orange[200], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.hotPink, AppColors.violet]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(count.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }

  // ── Task Card with Swipe Actions + Hero ──
  Widget _buildTaskCard(Task task) {
    final isDone = task.status == 'done';
    final heroTag = 'task_${task.id ?? task.hashCode}';

    return Dismissible(
      key: Key(heroTag),
      direction: isDone ? DismissDirection.endToStart : DismissDirection.horizontal,
      // Swipe Right → Complete
      onDismissed: (direction) {
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.startToEnd && !isDone) {
          // Mark complete
          final updated = Task(
            id: task.id,
            title: task.title,
            description: task.description,
            status: 'done',
            timestamp: task.timestamp,
            synced: task.synced,
          );
          ref.read(taskProvider.notifier).updateTask(updated);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Task completed!'),
              backgroundColor: AppColors.mint.withValues(alpha: 0.9),
            ),
          );
        } else {
          // Delete
          if (task.id != null) {
            ref.read(taskProvider.notifier).deleteLocalTask(task.id!);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Task deleted'),
              backgroundColor: AppColors.hotPink.withValues(alpha: 0.9),
            ),
          );
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd && isDone) return false;
        return true;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.mint.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.mint),
            const SizedBox(width: 8),
            Text('Complete', style: TextStyle(color: AppColors.mint, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.hotPink.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Delete', style: TextStyle(color: AppColors.hotPink, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            const Icon(Icons.delete_outline_rounded, color: AppColors.hotPink),
          ],
        ),
      ),
      child: _AnimatedPressButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          Navigator.push(context, _SlideUpRoute(page: TaskDetailScreen(task: task, heroTag: heroTag)));
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDone ? AppColors.mint.withValues(alpha: 0.12) : AppColors.violet.withValues(alpha: 0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Hero(
                  tag: heroTag,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isDone
                          ? LinearGradient(colors: [
                              AppColors.mint.withValues(alpha: 0.2),
                              AppColors.mint.withValues(alpha: 0.05),
                            ])
                          : const LinearGradient(colors: [AppColors.hotPink, AppColors.violet]),
                    ),
                    child: Icon(
                      isDone ? Icons.check_rounded : Icons.auto_awesome,
                      color: isDone ? AppColors.mint : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(task.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            task.synced ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
                            size: 13,
                            color: task.synced ? AppColors.mint : Colors.orange[300],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.synced ? 'Synced' : 'Pending sync',
                            style: TextStyle(fontSize: 11, color: task.synced ? AppColors.mint : Colors.orange[300]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Shimmer Loading ──
  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _shimmerBox(200, 28),
          const SizedBox(height: 6),
          _shimmerBox(160, 16),
          const SizedBox(height: 24),
          _shimmerBox(double.infinity, 110, radius: 22),
          const SizedBox(height: 24),
          _shimmerBox(120, 20),
          const SizedBox(height: 12),
          _shimmerBox(double.infinity, 80, radius: 18),
          const SizedBox(height: 10),
          _shimmerBox(double.infinity, 80, radius: 18),
          const SizedBox(height: 10),
          _shimmerBox(double.infinity, 80, radius: 18),
        ],
      ),
    );
  }

  Widget _shimmerBox(double width, double height, {double radius = 12}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.6),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.cardLight.withValues(alpha: value),
            borderRadius: BorderRadius.circular(radius),
          ),
        );
      },
    );
  }

  // ── Empty ──
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.hotPink, AppColors.violet],
                  ).createShader(bounds),
                  child: const Icon(Icons.auto_awesome, size: 72, color: Colors.white),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text('No tasks yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            'Tap + to create your first task',
            style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object e) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 56, color: AppColors.hotPink.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('Error loading tasks', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
          const SizedBox(height: 8),
          Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.refresh(taskProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ── Add Task Dialog ──
  void _showAddTaskDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Task',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, anim, secondAnim, child) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curve),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (context, anim, secondAnim) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width - 48,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.violet.withValues(alpha: 0.15)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppColors.hotPink, AppColors.violet],
                        ).createShader(bounds),
                        child: const Icon(Icons.add_task_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 10),
                      const Text('New Task', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      prefixIcon: Icon(Icons.title_rounded, color: AppColors.textSecondary),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                    textCapitalization: TextCapitalization.sentences,
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description_outlined, color: AppColors.textSecondary),
                      alignLabelWithHint: true,
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _titleController.clear();
                            _descController.clear();
                          },
                          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(colors: [AppColors.hotPink, AppColors.violet]),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (_titleController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Title cannot be empty')),
                                );
                                return;
                              }
                              HapticFeedback.mediumImpact();
                              final now = DateTime.now().millisecondsSinceEpoch;
                              final task = Task(
                                title: _titleController.text,
                                description: _descController.text,
                                status: 'pending',
                                timestamp: now,
                              );
                              ref.read(taskProvider.notifier).addDraftTask(task);
                              Navigator.pop(context);
                              _titleController.clear();
                              _descController.clear();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Task created!'),
                                  backgroundColor: AppColors.mint.withValues(alpha: 0.9),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Create Task', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Logout Dialog ──
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sign Out', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authService = ref.read(authServiceProvider);
              try {
                await authService.signOut();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sign out error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.hotPink),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveDataTab() => const _LiveDataView();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _fabController.dispose();
    _headerController.dispose();
    _statsController.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════
// Animated Task Entry (Stagger slide-in)
// ═══════════════════════════════════════════════
class _AnimatedTaskEntry extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedTaskEntry({required this.index, required this.child});

  @override
  State<_AnimatedTaskEntry> createState() => _AnimatedTaskEntryState();
}

class _AnimatedTaskEntryState extends State<_AnimatedTaskEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: _controller,
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════
// Animated Press Button (scale down on press)
// ═══════════════════════════════════════════════
class _AnimatedPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  const _AnimatedPressButton({required this.child, this.onPressed});

  @override
  State<_AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<_AnimatedPressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.06,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - _controller.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════
// Progress Ring Painter
// ═══════════════════════════════════════════════
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  _ProgressRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    const strokeWidth = 6.0;

    final bgPaint = Paint()
      ..color = AppColors.cardLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: const [AppColors.hotPink, AppColors.violet, AppColors.mint],
      );
      final progressPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        rect.inflate(-strokeWidth / 2 + 3),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════
// Live Data View
// ═══════════════════════════════════════════════
class _LiveDataView extends ConsumerWidget {
  const _LiveDataView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiService = ref.read(apiServiceProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.hotPink, AppColors.violet],
                  ).createShader(bounds),
                  child: const Icon(Icons.insights_rounded, size: 28, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Text('Live Data', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            labelColor: AppColors.hotPink,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.hotPink,
            indicatorWeight: 3,
            dividerColor: AppColors.violet.withValues(alpha: 0.1),
            tabs: const [Tab(text: 'Weather'), Tab(text: 'Currency')],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildWeatherView(apiService, context),
                _buildCurrencyView(apiService),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherView(ApiService apiService, BuildContext context) {
    return FutureBuilder<Weather>(
      future: apiService.fetchCurrentWeather(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.hotPink));
        }
        if (snapshot.hasError) return _buildError(snapshot.error.toString());
        final weather = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.hotPink.withValues(alpha: 0.15),
                      AppColors.violet.withValues(alpha: 0.1),
                      AppColors.cardDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.violet.withValues(alpha: 0.12)),
                ),
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(colors: [AppColors.hotPink, AppColors.violet]).createShader(bounds),
                      child: Icon(_getWeatherIcon(weather.condition), size: 64, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text('${weather.temperature.toStringAsFixed(1)}°F',
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    Text(weather.condition, style: const TextStyle(fontSize: 16, color: AppColors.softLavender)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildWeatherDetail(Icons.location_on_outlined, 'Location', weather.location)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildWeatherDetail(Icons.air_rounded, 'Wind', '${weather.windSpeed.toStringAsFixed(1)} mph')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppColors.softLavender),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildCurrencyView(ApiService apiService) {
    return FutureBuilder<List<ExchangeRate>>(
      future: apiService.fetchExchangeRates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.hotPink));
        }
        if (snapshot.hasError) return _buildError(snapshot.error.toString());
        final rates = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rates.length,
          itemBuilder: (context, index) {
            final rate = rates[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + index * 60),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.violet.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [
                          AppColors.hotPink.withValues(alpha: 0.2),
                          AppColors.violet.withValues(alpha: 0.1),
                        ]),
                      ),
                      child: Center(
                        child: Text(rate.currency.substring(0, 1),
                            style: const TextStyle(color: AppColors.hotPink, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Text(rate.currency,
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 15))),
                    Text(rate.rate.toStringAsFixed(4),
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.softLavender, fontSize: 15)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.hotPink.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear sky': return Icons.wb_sunny_rounded;
      case 'partly cloudy': return Icons.cloud_rounded;
      case 'foggy': return Icons.foggy;
      case 'drizzle':
      case 'rainy': return Icons.umbrella_rounded;
      case 'snowy': return Icons.ac_unit_rounded;
      case 'thunderstorm': return Icons.thunderstorm_rounded;
      default: return Icons.cloud_rounded;
    }
  }
}
