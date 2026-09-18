import 'package:flutter/material.dart';
import 'package:frontend/models/review_report.dart';
import 'package:frontend/screens/review/pr_review_detail_screen.dart';
import 'package:frontend/screens/studio/dashboard_tab.dart';
import 'package:frontend/screens/studio/pr_reviews_tab.dart';
import 'package:frontend/screens/studio/repositories_tab.dart';
import 'package:frontend/theme/theme.dart';

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
  bool _sidebarCollapsed = false;

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
                  collapsed: false,
                  onToggle: () {},
                ),
              ),
            ),
      body: desktop
          ? Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOutCubic,
                  width: _sidebarCollapsed ? 88 : 268,
                  child: _Sidebar(
                    section: _section,
                    onSelect: _openSection,
                    onLogout: widget.onLogout,
                    collapsed: _sidebarCollapsed,
                    onToggle: () {
                      setState(() {
                        _sidebarCollapsed = !_sidebarCollapsed;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    child: KeyedSubtree(
                      key: ValueKey(_section),
                      child: content,
                    ),
                  ),
                ),
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
  const _Sidebar({
    required this.section,
    required this.onSelect,
    required this.onLogout,
    required this.collapsed,
    required this.onToggle,
  });

  final StudioSection section;
  final ValueChanged<StudioSection> onSelect;
  final VoidCallback onLogout;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final navItems = [
      _SidebarItem(
        title: 'Dashboard',
        icon: Icons.dashboard_rounded,
        selected: section == StudioSection.dashboard,
        onTap: () => onSelect(StudioSection.dashboard),
      ),
      _SidebarItem(
        title: 'Repositories',
        icon: Icons.hub_rounded,
        selected: section == StudioSection.repositories,
        onTap: () => onSelect(StudioSection.repositories),
      ),
      _SidebarItem(
        title: 'PR Reviews',
        icon: Icons.rate_review_rounded,
        selected: section == StudioSection.prReviews,
        onTap: () => onSelect(StudioSection.prReviews),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOutCubic,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: collapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    const SizedBox(width: 12),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          colors: [AppColors.accentPurple, AppColors.accent],
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    if (!collapsed) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Workspace',
                          style: Theme.of(context).textTheme.labelLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Align(
              alignment: collapsed ? Alignment.center : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: IconButton(
                  onPressed: onToggle,
                  tooltip: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
                  icon: Icon(
                    collapsed
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...navItems.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOutCubic,
                  decoration: BoxDecoration(
                    color: item.selected
                        ? AppColors.accent.withOpacity(0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: item.selected
                          ? AppColors.accent.withOpacity(0.35)
                          : AppColors.border,
                    ),
                  ),
                  child: item.build(context, collapsed),
                ),
              );
            }),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.accent,
                      child: Icon(Icons.person_rounded, size: 18, color: Colors.white),
                    ),
                    if (!collapsed) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GitHub Connected',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'App installed',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: collapsed ? const Icon(Icons.logout_rounded) : const Text('Logout'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem {
  const _SidebarItem({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  Widget build(BuildContext context, bool collapsed) {
    final Color textColor = selected
        ? AppColors.textPrimary
        : AppColors.textSecondary;
    final Color iconColor = selected ? AppColors.accent : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: collapsed ? 0 : 14,
          vertical: 12,
        ),
        height: collapsed ? 48 : 52,
        child: Row(
          mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: iconColor),
            if (!collapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: textColor,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
