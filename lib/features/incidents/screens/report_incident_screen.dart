import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  static const _categories = [
    _IncidentCategory(
      name: 'Medical',
      icon: Icons.medical_services_outlined,
      color: AppColors.emergencyRed,
      background: Color(0xFFFFF1F0),
    ),
    _IncidentCategory(
      name: 'Fire',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFE87524),
      background: Color(0xFFFFF5EA),
    ),
    _IncidentCategory(
      name: 'Accident',
      icon: Icons.car_crash_rounded,
      color: AppColors.accentBlue,
      background: Color(0xFFEEF5FF),
    ),
    _IncidentCategory(
      name: 'Safety',
      icon: Icons.shield_outlined,
      color: AppColors.successGreen,
      background: Color(0xFFECF7F1),
    ),
  ];

  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    if (_categories.any(
      (category) => category.name == widget.initialCategory,
    )) {
      _selectedCategory = widget.initialCategory;
    }
  }

  Future<void> _submitReport() async {
    final isValid = _formKey.currentState!.validate();
    setState(() {
      _categoryError = _selectedCategory == null
          ? 'Select an emergency category.'
          : null;
    });
    if (!isValid || _selectedCategory == null) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.info_outline_rounded),
        title: const Text('Report not submitted'),
        content: const Text(
          'Backend submission is not implemented yet. '
          'Your emergency report has not been sent or saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLocationNotice() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('GPS integration will be implemented later.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Emergency')),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth > 600 ? 32.0 : 20.0;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      8,
                      horizontalPadding,
                      24,
                    ),
                    children: [
                      _SectionLabel(
                        title: 'Emergency category',
                        subtitle: 'Choose the type of help needed.',
                      ),
                      const SizedBox(height: 12),
                      _buildCategoryChoices(),
                      if (_categoryError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _categoryError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _SectionLabel(
                        title: 'Description',
                        subtitle: 'Share the details responders should know.',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        maxLines: 5,
                        minLines: 4,
                        maxLength: 500,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Describe the emergency',
                          alignLabelWithHint: true,
                          helperText: 'Include what happened and where.',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Describe the emergency.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _SectionLabel(
                        title: 'Location',
                        subtitle: 'A location can help responders find you.',
                      ),
                      const SizedBox(height: 12),
                      _LocationCard(onAddLocation: _showLocationNotice),
                      const SizedBox(height: 24),
                      _SectionLabel(
                        title: 'Optional details',
                        subtitle: 'Add any information that may be helpful.',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Number of people affected',
                          hintText: 'For example, 2',
                          prefixIcon: Icon(Icons.people_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        maxLines: 3,
                        minLines: 2,
                        maxLength: 300,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Additional information',
                          hintText: 'Injuries, hazards, or other details',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitReport,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Submit Emergency Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emergencyRed,
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChoices() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 10.0;
        final cardWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _categories
              .map(
                (category) => SizedBox(
                  width: cardWidth,
                  child: _CategoryCard(
                    category: category,
                    selected: _selectedCategory == category.name,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category.name;
                        _categoryError = null;
                      });
                    },
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _IncidentCategory {
  const _IncidentCategory({
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final _IncidentCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? category.color : const Color(0xFFE8ECF2);

    return Material(
      color: selected ? category.background : AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(category.icon, color: category.color, size: 23),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: category.color),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.onAddLocation});

  final VoidCallback onAddLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppColors.accentBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Location not added',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onAddLocation,
            child: const Text('Add Location'),
          ),
        ],
      ),
    );
  }
}
