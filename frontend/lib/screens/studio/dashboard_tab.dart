import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/models/review_report.dart';
import 'package:frontend/theme/theme.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab(
      {super.key,
      required this.reports,
      required this.onConnectRepository,
      required this.onOpenReviewTab,
      required this.onOpenDetail});

  final List<ReviewReport> reports;
  final VoidCallback onConnectRepository;
  final ValueChanged<ReviewReport> onOpenReviewTab;
  final ValueChanged<ReviewReport> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final int completed =
        reports.where((r) => r.status.toLowerCase() == 'completed').length;
    final int processing =
        reports.where((r) => r.status.toLowerCase() == 'processing').length;
    final int failed =
        reports.where((r) => r.status.toLowerCase() == 'failed').length;
    final int bugsCaught = reports.fold<int>(
        0, (sum, report) => sum + report.structuralComments.length);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Actions',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                        'Real-time autonomous reviews for connected repositories',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: onConnectRepository,
                icon: const Icon(Icons.add_link_rounded),
                label: const Text('Connect Repository'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool compact = constraints.maxWidth < 880;
              final cards = [
                _MetricCard(
                    title: 'Total PRs Reviewed',
                    value: reports.length.toString(),
                    icon: Icons.merge_type_rounded),
                _MetricCard(
                    title: 'Bugs Caught',
                    value: bugsCaught.toString(),
                    icon: Icons.bug_report_rounded),
                _MetricCard(
                    title: 'In Progress',
                    value: processing.toString(),
                    icon: Icons.autorenew_rounded),
                _MetricCard(
                    title: 'Failed Runs',
                    value: failed.toString(),
                    icon: Icons.error_outline_rounded),
              ];

              if (compact) {
                return Column(
                    children: cards
                        .map((card) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: card))
                        .toList());
              }

              return Row(
                children: cards
                    .asMap()
                    .entries
                    .map(
                      (entry) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: entry.key == cards.length - 1 ? 0 : 12,
                          ),
                          child: entry.value,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Activity Feed',
                          style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      _StatusChip(
                          label: 'Completed: $completed',
                          color: AppColors.success),
                      const SizedBox(width: 8),
                      _StatusChip(
                          label: 'Processing: $processing',
                          color: AppColors.warning),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (reports.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border)),
                      child: const Text(
                          'No review activity yet. Connect repositories to begin.'),
                    )
                  else
                    ...reports.take(12).map((report) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ActivityTile(
                          report: report,
                          onTap: () => onOpenReviewTab(report),
                          onDetailTap: () => onOpenDetail(report),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.title, required this.value, required this.icon});

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis))
            ]),
            const SizedBox(height: 10),
            Text(value,
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile(
      {required this.report, required this.onTap, required this.onDetailTap});

  final ReviewReport report;
  final VoidCallback onTap;
  final VoidCallback onDetailTap;

  @override
  Widget build(BuildContext context) {
    final String status = report.status.toLowerCase();
    final bool isCompleted = status == 'completed';
    final bool isProcessing = status == 'processing';
    final bool isFailed = status == 'failed';
    final Color statusColor = isCompleted
        ? AppColors.success
        : isProcessing
            ? AppColors.warning
            : isFailed
                ? AppColors.error
                : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
            color: AppColors.surface),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          title: Text('${report.repoName}  #${report.prNumber}',
              style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text('Tap to open PR Reviews',
              style: Theme.of(context).textTheme.bodyMedium),
          trailing: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusChip(label: _statusLabel(status), color: statusColor),
              OutlinedButton(
                onPressed: onDetailTap,
                child: const Text('Open'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Review Completed';
      case 'processing':
        return 'Processing';
      case 'failed':
        return 'Failed';
      default:
        return 'Queued';
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.45))),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
