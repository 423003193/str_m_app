import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final Task task;
  final String? heroTag;

  const TaskDetailScreen({super.key, required this.task, this.heroTag});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');
    final formattedDate = dateFormat
        .format(DateTime.fromMillisecondsSinceEpoch(widget.task.timestamp));
    final isDone = widget.task.status == 'done';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: AppColors.hotPink.withValues(alpha: 0.7)),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge - gradient pill
            // Status badge with Hero
            Center(
              child: widget.heroTag != null
                  ? Hero(
                      tag: widget.heroTag!,
                      child: _buildStatusBadge(isDone),
                    )
                  : _buildStatusBadge(isDone),
            ),
            const SizedBox(height: 28),

            // Title section
            Text(
              'TITLE',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.task.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 24),

            // Description section
            Text(
              'DESCRIPTION',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.violet.withValues(alpha: 0.12)),
              ),
              child: Text(
                widget.task.description.isEmpty
                    ? 'No description provided.'
                    : widget.task.description,
                style: TextStyle(
                  color: widget.task.description.isEmpty
                      ? AppColors.textSecondary.withValues(alpha: 0.5)
                      : AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.6,
                  fontStyle: widget.task.description.isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Metadata Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.violet.withValues(alpha: 0.12)),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    icon: Icons.calendar_today_rounded,
                    label: 'Created',
                    value: formattedDate,
                    gradientColors: const [AppColors.hotPink, AppColors.violet],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Divider(
                      color: AppColors.violet.withValues(alpha: 0.1),
                      thickness: 1,
                    ),
                  ),
                  _buildDetailRow(
                    context,
                    icon: widget.task.synced
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_upload_outlined,
                    label: 'Sync Status',
                    value: widget.task.synced ? 'Synced' : 'Not Synced',
                    gradientColors: widget.task.synced
                        ? [AppColors.mint, AppColors.mint]
                        : [Colors.orange, Colors.deepOrange],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Delete button
            Center(
              child: TextButton.icon(
                onPressed: () => _showDeleteConfirmation(context),
                icon: Icon(Icons.delete_outline_rounded,
                    color: AppColors.hotPink.withValues(alpha: 0.6), size: 18),
                label: Text(
                  'Delete this task',
                  style: TextStyle(
                    color: AppColors.hotPink.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.hotPink.withValues(alpha: 0.2)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isDone) {
    return Container(
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
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradientColors,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: gradientColors.map((c) => c.withValues(alpha: 0.15)).toList(),
            ),
          ),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: gradientColors,
            ).createShader(bounds),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.hotPink),
            const SizedBox(width: 8),
            const Text('Delete Task?', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this task? This cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (widget.task.id != null) {
                ref
                    .read(taskProvider.notifier)
                    .deleteLocalTask(widget.task.id!);
              }
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Task deleted'),
                  backgroundColor: AppColors.hotPink.withValues(alpha: 0.9),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.hotPink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
