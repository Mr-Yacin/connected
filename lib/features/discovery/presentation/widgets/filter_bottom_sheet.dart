import 'package:flutter/material.dart';
import '../../../../core/models/discovery_filters.dart';
import '../../../../core/models/country_code.dart';
import '../../../../core/theme/app_colors.dart';

/// Bottom sheet for selecting discovery filters
class FilterBottomSheet extends StatefulWidget {
  final DiscoveryFilters initialFilters;
  final Function(DiscoveryFilters) onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? selectedCountry;
  late String? selectedDialect;
  late int? minAge;
  late int? maxAge;

  @override
  void initState() {
    super.initState();
    selectedCountry = widget.initialFilters.country;
    selectedDialect = widget.initialFilters.dialect;
    minAge = widget.initialFilters.minAge;
    maxAge = widget.initialFilters.maxAge;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الفلاتر',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedCountry = null;
                    selectedDialect = null;
                    minAge = null;
                    maxAge = null;
                  });
                },
                child: const Text('إعادة تعيين'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Country Filter
          Text(
            'الدولة',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedCountry,
            decoration: InputDecoration(
              hintText: 'اختر الدولة',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: CountryCodes.arabCountries.map((country) {
              return DropdownMenuItem(
                value: country.nameAr,
                child: Text(country.nameAr),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCountry = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Dialect Filter
          Text(
            'اللهجة',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedDialect,
            decoration: InputDecoration(
              hintText: 'اختر اللهجة',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: _arabicDialects.map((dialect) {
              return DropdownMenuItem(
                value: dialect,
                child: Text(dialect),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedDialect = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Age Range
          Text(
            'العمر',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: minAge?.toString(),
                  decoration: InputDecoration(
                    hintText: 'من',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      minAge = int.tryParse(value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: maxAge?.toString(),
                  decoration: InputDecoration(
                    hintText: 'إلى',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      maxAge = int.tryParse(value);
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Apply Button
          ElevatedButton(
            onPressed: () {
              final filters = DiscoveryFilters(
                country: selectedCountry,
                dialect: selectedDialect,
                minAge: minAge,
                maxAge: maxAge,
                excludedUserIds: widget.initialFilters.excludedUserIds,
              );
              widget.onApply(filters);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'تطبيق الفلاتر',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

// Arabic dialects list
const List<String> _arabicDialects = [
  'المصرية',
  'الخليجية',
  'الشامية',
  'المغاربية',
  'العراقية',
  'اليمنية',
  'السودانية',
];
