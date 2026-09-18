import 'package:flutter/material.dart';
import 'package:frontend/models/review_report.dart';
import 'package:frontend/theme/theme.dart';

class PRReviewsTab extends StatelessWidget {
  const PRReviewsTab(
      {super.key,
      required this.reports,
      required this.selectedReport,
      required this.onOpenDetail});

  final List<ReviewReport> reports;
  final ReviewReport? selectedReport;
  final ValueChanged<ReviewReport> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PR Reviews', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
              'Browse review runs from the activity feed and open the full detail view.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          if (selectedReport != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${selectedReport!.repoName} #${selectedReport!.prNumber}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Selected from the activity feed',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => onOpenDetail(selectedReport!),
                      child: const Text('Open Detail'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (reports.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border)),
              child: const Text('No PR reviews available yet.'),
            )
          else
            ...reports.map(
              (report) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${report.repoName} #${report.prNumber}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              report.fileChangesSummary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      _StatusChip(
                        label: _statusLabel(report.status),
                        color: _statusColor(report.status),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => onOpenDetail(report),
                        child: const Text('View'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    final value = status.toLowerCase();
    if (value == 'completed') return 'Passed';
    if (value == 'processing') return 'Agent Reviewing';
    if (value == 'failed') return 'Bugs Found';
    if (value == 'clean') return 'Passed';
    return 'Queued';
  }

  Color _statusColor(String status) {
    final value = status.toLowerCase();
    if (value == 'completed' || value == 'clean') return AppColors.success;
    if (value == 'processing') return AppColors.warning;
    if (value == 'failed') return AppColors.error;
    return AppColors.textSecondary;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
        ),
      ),
    );
  }
}
