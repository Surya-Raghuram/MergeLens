import 'package:flutter/material.dart';
import 'package:frontend/models/review_report.dart';
import 'package:frontend/screens/review/pr_review_detail_screen.dart';
import 'package:frontend/screens/studio/dashboard_tab.dart';
import 'package:frontend/screens/studio/pr_reviews_tab.dart';
import 'package:frontend/screens/studio/repositories_tab.dart';

class StudioShell extends StatefulWidget {
  const StudioShell(
      {super.key,
      required this.reports,
      required this.onConnectRepository,
      required this.onLogout});

  final List<ReviewReport> reports;
  final VoidCallback onConnectRepository;
  final VoidCallback onLogout;

  @override
  State<StudioShell> createState() => _StudioShellState();
}

class _StudioShellState extends State<StudioShell> {
  StudioSection _section = StudioSection.dashboard;
  ReviewReport? _selectedReport;

  void _openSection(StudioSection section, {ReviewReport? report}) {
    setState(() {
      _section = section;
      _selectedReport = report;
    });
  }

  void _openReview(ReviewReport report) {
    setState(() {
      _section = StudioSection.prReviews;
      _selectedReport = report;
    });
  }

  void _openDetail(ReviewReport report) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PRReviewDetailScreen(report: report),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool desktop = MediaQuery.sizeOf(context).width >= 1024;

    final Widget content = switch (_section) {
      StudioSection.dashboard => DashboardTab(
          reports: widget.reports,
          onConnectRepository: widget.onConnectRepository,
          onOpenReviewTab: _openReview,
          onOpenDetail: _openDetail,
        ),
      StudioSection.repositories => RepositoriesTab(
          reports: widget.reports,
          onConnectRepository: widget.onConnectRepository,
        ),
      StudioSection.prReviews => PRReviewsTab(
          reports: widget.reports,
          selectedReport: _selectedReport,
          onOpenDetail: _openDetail,
        ),
    };

    return Scaffold(
      appBar: desktop
          ? null
          : AppBar(
              title: const Text('MergeLens Studio'),
              actions: [
                IconButton(
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
      drawer: desktop
          ? null
          : Drawer(
              child: SafeArea(
                child: _Sidebar(
                  section: _section,
                  onSelect: _openSection,
                  onLogout: widget.onLogout,
                ),
              ),
            ),
      body: desktop
          ? Row(
              children: [
                _Sidebar(
                  section: _section,
                  onSelect: _openSection,
                  onLogout: widget.onLogout,
                ),
                Expanded(child: content),
              ],
            )
          : content,
      bottomNavigationBar: desktop
          ? null
          : NavigationBar(
              selectedIndex: _section.index,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.hub_outlined),
                  selectedIcon: Icon(Icons.hub_rounded),
                  label: 'Repos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.rate_review_outlined),
                  selectedIcon: Icon(Icons.rate_review_rounded),
                  label: 'PR Reviews',
                ),
              ],
              onDestinationSelected: (index) {
                _openSection(StudioSection.values[index]);
              },
            ),
    );
  }
}

enum StudioSection { dashboard, repositories, prReviews }

class _Sidebar extends StatelessWidget {
  const _Sidebar(
      {required this.section, required this.onSelect, required this.onLogout});

  final StudioSection section;
  final ValueChanged<StudioSection> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF141417),
        border: Border(right: BorderSide(color: Color(0xFF2A2A2D))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Workspace',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: 12),
          _SidebarTab(
            title: 'Dashboard',
            icon: Icons.dashboard_rounded,
            selected: section == StudioSection.dashboard,
            onTap: () => onSelect(StudioSection.dashboard),
          ),
          _SidebarTab(
            title: 'Repositories',
            icon: Icons.hub_rounded,
            selected: section == StudioSection.repositories,
            onTap: () => onSelect(StudioSection.repositories),
          ),
          _SidebarTab(
            title: 'PR Reviews',
            icon: Icons.rate_review_rounded,
            selected: section == StudioSection.prReviews,
            onTap: () => onSelect(StudioSection.prReviews),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTab extends StatelessWidget {
  const _SidebarTab(
      {required this.title,
      required this.icon,
      required this.selected,
      required this.onTap});

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor =
        selected ? const Color(0xFF4DA3FF) : const Color(0xFF2A2A2D);
    final Color textColor =
        selected ? const Color(0xFFEDEEF0) : const Color(0xFFA6A8AF);
    final Color iconColor =
        selected ? const Color(0xFF4DA3FF) : const Color(0xFFA6A8AF);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF4DA3FF).withOpacity(0.10)
                : const Color(0xFF141417),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 10),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: textColor)),
            ],
          ),
        ),
      ),
    );
  }
}
