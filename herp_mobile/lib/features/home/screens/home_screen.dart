import 'package:flutter/material.dart';

import '../../ble/screens/nearby_devices_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../incidents/screens/report_incident_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOnline = true;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth > 600 ? 32.0 : 20.0;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        18,
                        horizontalPadding,
                        28,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _HomeHeader(
                            onProfileTap: () => _showMessage(
                              'Profile will be available later.',
                            ),
                          ),
                          const SizedBox(height: 22),
                          _ConnectionStatusCard(
                            isOnline: _isOnline,
                            onStatusChanged: (value) {
                              setState(() => _isOnline = value);
                            },
                          ),
                          const SizedBox(height: 18),
                          _EmergencyActionCard(
                            onReportTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) =>
                                    const ReportIncidentScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const NearbyDevicesScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.bluetooth_searching),
                            label: const Text('Nearby HERP Devices'),
                          ),
                          const SizedBox(height: 28),
                          _SectionHeading(
                            title: 'Emergency Services',
                            textTheme: textTheme,
                          ),
                          const SizedBox(height: 14),
                          _EmergencyCategoryGrid(
                            onCategoryTap: (category) =>
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (context) => ReportIncidentScreen(
                                      initialCategory: category,
                                    ),
                                  ),
                                ),
                          ),
                          const SizedBox(height: 28),
                          _SectionHeading(
                            title: 'Recent Incidents',
                            textTheme: textTheme,
                            actionLabel: 'View All',
                            onActionTap: () => _showMessage(
                              'Incident history will be implemented later.',
                            ),
                          ),
                          const SizedBox(height: 14),
                          ..._demoIncidents.map(
                            (incident) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _RecentIncidentCard(incident: incident),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 0) return;
          final destination = switch (index) {
            1 => 'My Incidents',
            2 => 'Help',
            _ => 'Profile',
          };
          _showMessage('$destination will be available later.');
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'My Incidents',
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline_rounded),
            selectedIcon: Icon(Icons.help_rounded),
            label: 'Help',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onProfileTap});

  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.health_and_safety_rounded,
            color: AppColors.cardBackground,
            size: 27,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, Citizen',
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text('Your safety matters.', style: textTheme.bodyMedium),
            ],
          ),
        ),
        IconButton(
          onPressed: onProfileTap,
          tooltip: 'Profile',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.cardBackground,
            foregroundColor: AppColors.primaryNavy,
            minimumSize: const Size(48, 48),
          ),
          icon: const Icon(Icons.account_circle_outlined, size: 27),
        ),
      ],
    );
  }
}

class _ConnectionStatusCard extends StatelessWidget {
  const _ConnectionStatusCard({
    required this.isOnline,
    required this.onStatusChanged,
  });

  final bool isOnline;
  final ValueChanged<bool> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final statusColor = isOnline
        ? AppColors.successGreen
        : AppColors.emergencyRed;

    return _SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 7),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isOnline
                      ? 'Network available (demo status)'
                      : 'No network available (demo status)',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 5),
                Text(
                  'Pending reports: 0',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: isOnline,
                onChanged: onStatusChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Text(
                'Demo toggle',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: AppColors.secondaryText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmergencyActionCard extends StatelessWidget {
  const _EmergencyActionCard({required this.onReportTap});

  final VoidCallback onReportTap;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      color: const Color(0xFFFFF7F6),
      borderColor: const Color(0xFFF5D1CF),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.emergencyRed.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.crisis_alert_rounded,
                  color: AppColors.emergencyRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Need Emergency Assistance?',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: AppColors.primaryNavy),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Report an incident to get help.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onReportTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emergencyRed,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.warning_rounded),
              label: const Text('Report Emergency'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyCategoryGrid extends StatelessWidget {
  const _EmergencyCategoryGrid({required this.onCategoryTap});

  final ValueChanged<String> onCategoryTap;

  static const _categories = [
    _EmergencyCategory(
      name: 'Medical',
      icon: Icons.medical_services_outlined,
      color: AppColors.emergencyRed,
      background: Color(0xFFFFF1F0),
    ),
    _EmergencyCategory(
      name: 'Fire',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFE87524),
      background: Color(0xFFFFF5EA),
    ),
    _EmergencyCategory(
      name: 'Accident',
      icon: Icons.car_crash_rounded,
      color: AppColors.accentBlue,
      background: Color(0xFFEEF5FF),
    ),
    _EmergencyCategory(
      name: 'Safety',
      icon: Icons.shield_outlined,
      color: AppColors.successGreen,
      background: Color(0xFFECF7F1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _categories
              .map(
                (category) => SizedBox(
                  width: cardWidth,
                  child: _EmergencyCategoryCard(
                    category: category,
                    onTap: () => onCategoryTap(category.name),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _EmergencyCategory {
  const _EmergencyCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String name;
  final IconData icon;
  final Color color;
  final Color background;
}

class _EmergencyCategoryCard extends StatelessWidget {
  const _EmergencyCategoryCard({required this.category, required this.onTap});

  final _EmergencyCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 106),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8ECF2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: category.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, color: category.color, size: 23),
              ),
              const SizedBox(height: 11),
              Text(
                category.name,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: AppColors.primaryNavy),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.textTheme,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final TextTheme textTheme;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontSize: 19,
              color: AppColors.primaryNavy,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _IncidentDemoData {
  const _IncidentDemoData({
    required this.title,
    required this.id,
    required this.timestamp,
    required this.status,
    required this.icon,
    required this.color,
    required this.statusColor,
    required this.statusBackground,
  });

  final String title;
  final String id;
  final String timestamp;
  final String status;
  final IconData icon;
  final Color color;
  final Color statusColor;
  final Color statusBackground;
}

const _demoIncidents = [
  _IncidentDemoData(
    title: 'Medical assistance',
    id: 'DEMO-2408',
    timestamp: '2 hours ago',
    status: 'Acknowledged',
    icon: Icons.medical_services_outlined,
    color: AppColors.emergencyRed,
    statusColor: AppColors.successGreen,
    statusBackground: Color(0xFFECF7F1),
  ),
  _IncidentDemoData(
    title: 'Road accident',
    id: 'DEMO-2407',
    timestamp: 'Yesterday',
    status: 'Pending',
    icon: Icons.car_crash_rounded,
    color: AppColors.accentBlue,
    statusColor: Color(0xFF986A00),
    statusBackground: Color(0xFFFFF6DF),
  ),
];

class _RecentIncidentCard extends StatelessWidget {
  const _RecentIncidentCard({required this.incident});

  final _IncidentDemoData incident;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: incident.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(incident.icon, color: incident.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  '${incident.id}  ·  ${incident.timestamp}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: incident.statusBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              incident.status,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: incident.statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.color = AppColors.cardBackground,
    this.borderColor = const Color(0xFFE8ECF2),
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final Color color;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A10233F),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
