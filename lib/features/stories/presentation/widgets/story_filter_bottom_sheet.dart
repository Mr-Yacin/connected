import 'package:flutter/material.dart';
import '../../../../core/models/discovery_filters.dart';
import '../../../../core/models/country_code.dart';
import '../../../../core/theme/app_colors.dart';

/// Bottom sheet for filtering stories in the story viewer
class StoryFilterBottomSheet extends StatefulWidget {
  final DiscoveryFilters initialFilters;
  final Function(DiscoveryFilters) onApply;

  const StoryFilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<StoryFilterBottomSheet> createState() => _StoryFilterBottomSheetState();
}

class _StoryFilterBottomSheetState extends State<StoryFilterBottomSheet> {
  late String? selectedCountry;
  late String? selectedGender;
  late RangeValues ageRange;

  @override
  void initState() {
    super.initState();
    selectedCountry = widget.initialFilters.country;
    selectedGender = widget.initialFilters.gender;
    
    // Initialize age range with default values if not set
    final minAge = widget.initialFilters.minAge?.toDouble() ?? 18.0;
    final maxAge = widget.initialFilters.maxAge?.toDouble() ?? 35.0;
    ageRange = RangeValues(minAge, maxAge);
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
                'تصفية القصص',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedCountry = null;
                    selectedGender = null;
                    ageRange = const RangeValues(18, 35);
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
          
          // Gender Filter
          Text(
            'الجنس',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _GenderOption(
                  label: 'الكل',
                  isSelected: selectedGender == null,
                  onTap: () {
                    setState(() {
                      selectedGender = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GenderOption(
                  label: 'ذكر',
                  isSelected: selectedGender == 'ذكر',
                  onTap: () {
                    setState(() {
                      selectedGender = 'ذكر';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GenderOption(
                  label: 'أنثى',
                  isSelected: selectedGender == 'أنثى',
                  onTap: () {
                    setState(() {
                      selectedGender = 'أنثى';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Age Range Slider
          Text(
            'العمر',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'من ${ageRange.start.round()}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'إلى ${ageRange.end.round() >= 35 ? "35+" : ageRange.end.round()}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          RangeSlider(
            values: ageRange,
            min: 18,
            max: 35,
            divisions: 17,
            labels: RangeLabels(
              '${ageRange.start.round()}',
              ageRange.end.round() >= 35 ? '35+' : '${ageRange.end.round()}',
            ),
            activeColor: AppColors.primary,
            onChanged: (RangeValues values) {
              setState(() {
                ageRange = values;
              });
            },
          ),
          const SizedBox(height: 24),
          
          // Apply Button
          ElevatedButton(
            onPressed: () {
              final filters = DiscoveryFilters(
                country: selectedCountry,
                gender: selectedGender,
                minAge: ageRange.start.round(),
                maxAge: ageRange.end.round() >= 35 ? null : ageRange.end.round(),
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
          SizedBox(
            height: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom,
          ),
        ],
      ),
    );
  }
}

// Gender option widget
class _GenderOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : null,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
