import 'package:flutter/material.dart';
import 'package:frontend/models/review_report.dart';
import 'package:frontend/theme/theme.dart';

class RepositoriesTab extends StatefulWidget {
  const RepositoriesTab(
      {super.key, required this.reports, required this.onConnectRepository});

  final List<ReviewReport> reports;
  final VoidCallback onConnectRepository;

  @override
  State<RepositoriesTab> createState() => _RepositoriesTabState();
}

class _RepositoriesTabState extends State<RepositoriesTab> {
  late final Map<String, bool> _enabledByRepo;

  @override
  void initState() {
    super.initState();
    _enabledByRepo = {
      for (final report in widget.reports) report.repoName: true
    };
  }

  @override
  void didUpdateWidget(covariant RepositoriesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final report in widget.reports) {
      _enabledByRepo.putIfAbsent(report.repoName, () => true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repoNames = widget.reports
        .map((report) => report.repoName)
        .toSet()
        .toList()
      ..sort();

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
                    Text('Connected Repositories',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                        'Manage GitHub App connections and pause or resume reviews per repo.',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: widget.onConnectRepository,
                icon: const Icon(Icons.add_link_rounded),
                label: const Text('Connect New Repository'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (repoNames.isEmpty)
            _EmptyState(onConnectRepository: widget.onConnectRepository)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final int columns = constraints.maxWidth > 1100
                    ? 3
                    : constraints.maxWidth > 700
                        ? 2
                        : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: repoNames.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.8,
                  ),
                  itemBuilder: (context, index) {
                    final repoName = repoNames[index];
                    final enabled = _enabledByRepo[repoName] ?? true;
                    final language = _guessLanguage(repoName, widget.reports);
                    final counts = widget.reports
                        .where((report) => report.repoName == repoName)
                        .length;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Icon(
                                  Icons.folder_rounded,
                                  color: AppColors.accent,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  repoName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            language,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _StatusChip(
                                label: '$counts PRs',
                                color: AppColors.accent,
                              ),
                              const Spacer(),
                              Switch.adaptive(
                                value: enabled,
                                activeColor: AppColors.accent,
                                onChanged: (value) {
                                  setState(() {
                                    _enabledByRepo[repoName] = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  String _guessLanguage(String repoName, List<ReviewReport> reports) {
    ReviewReport? report;
    for (final item in reports) {
      if (item.repoName == repoName) {
        report = item;
        break;
      }
    }
    if (report == null) return 'Unknown';
    final summary = report.fileChangesSummary.toLowerCase();
    if (summary.contains('dart')) return 'Dart';
    if (summary.contains('python')) return 'Python';
    if (summary.contains('cpp') || summary.contains('c++')) return 'C++';
    if (summary.contains('typescript') || summary.contains('.ts'))
      return 'TypeScript';
    return 'Unknown';
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onConnectRepository});

  final VoidCallback onConnectRepository;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No repositories connected yet',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Install the GitHub App to start autonomous PR reviews.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onConnectRepository,
            icon: const Icon(Icons.add_link_rounded),
            label: const Text('Connect New Repository'),
          ),
        ],
      ),
    );
  }
}
