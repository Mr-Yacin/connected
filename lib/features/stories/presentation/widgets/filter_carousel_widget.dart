import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/camera_filter.dart';

/// Filter carousel widget for camera screen
class FilterCarouselWidget extends StatefulWidget {
  final CameraFilter selectedFilter;
  final Function(CameraFilter) onFilterSelected;
  final Widget? previewImage;

  const FilterCarouselWidget({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    this.previewImage,
  });

  @override
  State<FilterCarouselWidget> createState() => _FilterCarouselWidgetState();
}

class _FilterCarouselWidgetState extends State<FilterCarouselWidget> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: CameraFilter.allFilters.length,
        itemBuilder: (context, index) {
          final filter = CameraFilter.allFilters[index];
          final isSelected = filter.id == widget.selectedFilter.id;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _FilterThumbnail(
              filter: filter,
              isSelected: isSelected,
              previewImage: widget.previewImage,
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onFilterSelected(filter);
              },
            ),
          );
        },
      ),
    );
  }
}

class _FilterThumbnail extends StatelessWidget {
  final CameraFilter filter;
  final bool isSelected;
  final Widget? previewImage;
  final VoidCallback onTap;

  const _FilterThumbnail({
    required this.filter,
    required this.isSelected,
    required this.onTap,
    this.previewImage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filter preview thumbnail
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
                width: isSelected ? 3 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Preview with filter applied
                  if (previewImage != null)
                    ColorFiltered(
                      colorFilter: filter.colorFilter,
                      child: previewImage,
                    )
                  else
                    // Fallback gradient preview
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.purple.shade400,
                            Colors.orange.shade400,
                          ],
                        ),
                      ),
                      child: ColorFiltered(
                        colorFilter: filter.colorFilter,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.purple.shade400,
                                Colors.orange.shade400,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Glass overlay for better aesthetics
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Filter name
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: isSelected ? 12 : 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            child: Text(
              filter.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget to apply filter to camera preview or image
class FilterPreviewWidget extends StatelessWidget {
  final Widget child;
  final CameraFilter filter;
  final double intensity;

  const FilterPreviewWidget({
    super.key,
    required this.child,
    required this.filter,
    this.intensity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (filter.id == 'none') {
      return child;
    }

    return ColorFiltered(
      colorFilter: filter.withIntensity(intensity),
      child: child,
    );
  }
}
