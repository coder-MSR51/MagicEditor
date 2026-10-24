import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/filter_presets.dart';

class FilterSelectorBar extends StatefulWidget {
  final FilterPreset currentFilter;
  final double filterIntensity;
  final Uint8List? thumbnailBytes;
  final Function(FilterPreset preset) onSelectFilter;
  final Function(double intensity) onIntensityChanged;

  const FilterSelectorBar({
    super.key,
    required this.currentFilter,
    required this.filterIntensity,
    this.thumbnailBytes,
    required this.onSelectFilter,
    required this.onIntensityChanged,
  });

  @override
  State<FilterSelectorBar> createState() => _FilterSelectorBarState();
}

class _FilterSelectorBarState extends State<FilterSelectorBar> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final filteredPresets = _selectedCategory == 'All'
        ? FilterPresets.all
        : FilterPresets.all
            .where((p) => p.category == _selectedCategory || p.id == 'original')
            .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Intensity Slider (Only when filter is not 'original')
        if (widget.currentFilter.id != 'original')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  '${widget.currentFilter.name} Intensity',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(widget.filterIntensity * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Slider(
                    value: widget.filterIntensity,
                    min: 0.0,
                    max: 1.0,
                    onChanged: widget.onIntensityChanged,
                  ),
                ),
              ],
            ),
          ),

        // Filter Category Chips
        SizedBox(
          height: 32,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: FilterPresets.categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final cat = FilterPresets.categories[index];
              final isSelected = _selectedCategory == cat;

              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.white12,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primary : Colors.white70,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 6),

        // Horizontal Preset Thumbnails
        SizedBox(
          height: 94,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            scrollDirection: Axis.horizontal,
            itemCount: filteredPresets.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final preset = filteredPresets[index];
              final isSelected = widget.currentFilter.id == preset.id;

              return GestureDetector(
                onTap: () => widget.onSelectFilter(preset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : Colors.white12,
                          width: isSelected ? 2.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.matrix(preset.matrix),
                          child: widget.thumbnailBytes != null
                              ? Image.memory(
                                  widget.thumbnailBytes!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFE65C00),
                                        Color(0xFFF9D423),
                                        Color(0xFF7B1FA2),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preset.name,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
