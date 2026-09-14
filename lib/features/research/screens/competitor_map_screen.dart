import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/tactile_card.dart';
import '../../../shared/widgets/vyapar_top_app_bar.dart';
import '../models/competitor_poi.dart';
import '../providers/competitor_provider.dart';
import '../widgets/hyperlocal_competitor_map.dart';

/// Screen displaying interactive Mappls hyperlocal competitor discovery.
class CompetitorMapScreen extends ConsumerStatefulWidget {
  const CompetitorMapScreen({super.key});

  @override
  ConsumerState<CompetitorMapScreen> createState() => _CompetitorMapScreenState();
}

class _CompetitorMapScreenState extends ConsumerState<CompetitorMapScreen> {
  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';
    final business = ref.watch(selectedBusinessProvider);
    final profile = ref.watch(businessProfileProvider);
    final currentRadius = ref.watch(competitorRadiusProvider);
    final selectedCompetitor = ref.watch(selectedCompetitorProvider);
    final competitorsAsync = ref.watch(competitorPoisProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VyaparTopAppBar(
        title: isHindi ? 'स्थानीय प्रतियोगी मानचित्र' : 'Hyperlocal Competitor Map',
        subtitle: '${business.title} • ${profile.block}',
        showAudioButton: true,
      ),
      body: SafeArea(
        child: competitorsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.secondary),
          ),
          error: (err, _) => Center(
            child: Text(
              isHindi ? 'मानचित्र लोड करने में त्रुटि' : 'Error loading competitor map: $err',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
          data: (competitors) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Radius Filter Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isHindi ? 'खोज दायरा:' : 'Search Radius:',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [3.0, 5.0, 10.0].map((r) {
                          final isSelected = currentRadius == r;
                          return Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: ChoiceChip(
                              label: Text('${r.toStringAsFixed(0)} km'),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.surfaceVariant,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              onSelected: (_) {
                                ref.read(competitorRadiusProvider.notifier).state = r;
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Mappls Map Widget
                  HyperlocalCompetitorMap(
                    competitors: competitors,
                    selectedCompetitor: selectedCompetitor,
                    radiusKm: currentRadius,
                    height: 320,
                    onCompetitorSelected: (comp) {
                      ref.read(selectedCompetitorProvider.notifier).state = comp;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Selected Competitor Inspector Card
                  if (selectedCompetitor != null) ...[
                    _buildCompetitorDetailCard(selectedCompetitor, isHindi),
                    const SizedBox(height: 16),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.touch_app_rounded, color: AppColors.info, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isHindi
                                  ? 'प्रतियोगी की क्षमता और मूल्य रणनीति देखने के लिए किसी भी पिन पर टैप करें।'
                                  : 'Tap any orange pin on the map to inspect competitor capacity & pricing strategy.',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Mapped Competitors Directory Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isHindi ? 'पहचाने गए प्रतियोगी (${competitors.length})' : 'Identified Competitors (${competitors.length})',
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      StatusBadge(
                        label: competitors.length <= 2
                            ? (isHindi ? 'कम प्रतिस्पर्धा' : 'Low Saturation')
                            : (isHindi ? 'मध्यम प्रतिस्पर्धा' : 'Moderate Saturation'),
                        type: competitors.length <= 2 ? BadgeType.success : BadgeType.warning,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Competitors List
                  ...competitors.map((comp) {
                    final isSelected = comp.id == selectedCompetitor?.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: GestureDetector(
                        onTap: () {
                          ref.read(selectedCompetitorProvider.notifier).state = comp;
                        },
                        child: TactileCard(
                          border: isSelected
                              ? Border.all(color: AppColors.error, width: 2)
                              : null,
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.errorBg : AppColors.surfaceVariant,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? AppColors.error : AppColors.border,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.store_rounded,
                                  color: isSelected ? AppColors.error : AppColors.secondary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comp.name,
                                      style: AppTypography.labelLarge.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${comp.address} • ${comp.distanceKm} km away',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompetitorDetailCard(CompetitorPoi comp, bool isHindi) {
    return TactileCard(
      border: Border.all(color: AppColors.secondary, width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  comp.name,
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              StatusBadge(
                label: '${comp.distanceKm} km',
                type: BadgeType.warning,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comp.address,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: _statBox(
                  isHindi ? 'अनुमानित क्षमता' : 'Est. Capacity',
                  comp.estimatedCapacity,
                  Icons.precision_manufacturing_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBox(
                  isHindi ? 'बाजार मूल्य' : 'Price Point',
                  comp.pricePoint,
                  Icons.currency_rupee_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_rounded, color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHindi ? 'व्यापार मित्र रणनीतिक सलाह:' : 'Vyapar Mitra Strategic Advantage:',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        comp.differentiationTip,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
