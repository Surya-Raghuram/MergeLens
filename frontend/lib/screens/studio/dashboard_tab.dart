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
    final int clean = reports
        .where((r) => r.status.toLowerCase() == 'clean')
        .length;
    final int bugsCaught = reports.fold<int>(
        0, (sum, report) => sum + report.structuralComments.length);

    final repoGroups = <String, int>{};
    for (final report in reports) {
      repoGroups[report.repoName] = (repoGroups[report.repoName] ?? 0) + 1;
    }

    final healthRows = repoGroups.entries.take(4).map((entry) {
      final status = entry.value > 0 ? 'Healthy' : 'Queued';
      return _RepoHealthRow(
        repoName: entry.key,
        prCount: entry.value,
        status: status,
      );
    }).toList();

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
              final bool compact = constraints.maxWidth < 900;
              final cards = [
                _MetricCard(
                    title: 'PRs Reviewed',
                    value: reports.length.toString(),
                    icon: Icons.merge_type_rounded),
                _MetricCard(
                    title: 'Bugs Caught',
                    value: bugsCaught.toString(),
                    icon: Icons.bug_report_rounded),
                _MetricCard(
                    title: 'Agent Reviewing',
                    value: processing.toString(),
                    icon: Icons.autorenew_rounded),
                _MetricCard(
                    title: 'Passed',
                    value: clean.toString(),
                    icon: Icons.check_circle_rounded),
              ];

              if (compact) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: cards
                      .map((card) => SizedBox(width: 220, child: card))
                      .toList(),
                );
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
          LayoutBuilder(
            builder: (context, constraints) {
              final bool wide = constraints.maxWidth >= 960;
              final content = [
                _DashboardPanel(
                  title: 'Repository Health',
                  child: Column(
                    children: healthRows.isEmpty
                        ? [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Text(
                                'No repositories connected yet. Connect a repo to begin checking health.',
                              ),
                            )
                          ]
                        : healthRows,
                  ),
                ),
                _DashboardPanel(
                  title: 'Recent PR Activity',
                  child: reports.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            'No review activity yet. Connect repositories to begin.',
                          ),
                        )
                      : Column(
                          children: reports.take(5).map((report) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ActivityTile(
                                report: report,
                                onTap: () => onOpenReviewTab(report),
                                onDetailTap: () => onOpenDetail(report),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ];

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: content[0]),
                    const SizedBox(width: 16),
                    Expanded(child: content[1]),
                  ],
                );
              }

              return Column(
                children: [
                  content[0],
                  const SizedBox(height: 16),
                  content[1],
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          _DashboardPanel(
            title: 'Activity Feed',
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(label: 'Passed: $completed', color: AppColors.success),
                    _StatusChip(label: 'Failed: $failed', color: AppColors.error),
                    _StatusChip(label: 'Agent Reviewing: $processing', color: AppColors.warning),
                    _StatusChip(label: 'Bugs Found: $bugsCaught', color: AppColors.error),
                  ],
                ),
                const SizedBox(height: 12),
                if (reports.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text('No review activity yet. Connect repositories to begin.'),
                  )
                else
                  ...reports.take(8).map((report) {
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
        ],
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            child,
          ],
        ),
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
            const SizedBox(height: 12),
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

class _RepoHealthRow extends StatelessWidget {
  const _RepoHealthRow({
    required this.repoName,
    required this.prCount,
    required this.status,
  });

  final String repoName;
  final int prCount;
  final String status;

  @override
  Widget build(BuildContext context) {
    final Color healthColor = status.toLowerCase() == 'healthy'
        ? AppColors.success
        : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: healthColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  repoName,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  '$prCount recent PRs',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          _StatusChip(label: status, color: healthColor),
        ],
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          color: AppColors.surfaceAlt,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${report.repoName}  #${report.prNumber}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    report.fileChangesSummary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _StatusChip(label: _statusLabel(status), color: statusColor),
                OutlinedButton(
                  onPressed: onDetailTap,
                  child: const Text('Open'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Passed';
      case 'processing':
        return 'Agent Reviewing';
      case 'failed':
        return 'Bugs Found';
      case 'clean':
        return 'Passed';
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
