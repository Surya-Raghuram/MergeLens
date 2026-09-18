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
              child: ListTile(
                title: Text(
                    '${selectedReport!.repoName}  #${selectedReport!.prNumber}'),
                subtitle: Text('Selected from the activity feed'),
                trailing: TextButton(
                  onPressed: () => onOpenDetail(selectedReport!),
                  child: const Text('Open Detail'),
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
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border)),
              child: const Text('No PR reviews available yet.'),
            )
          else
            ...reports.map(
              (report) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    title: Text('${report.repoName}  #${report.prNumber}'),
                    subtitle: Text(report.status),
                    trailing: TextButton(
                      onPressed: () => onOpenDetail(report),
                      child: const Text('View'),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
