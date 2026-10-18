import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/tactile_card.dart';
import '../models/supplier_logistics.dart';
import '../providers/logistics_provider.dart';

/// Interactive tactile card displaying Mappls-powered logistics & landed cost intelligence.
class LogisticsFeasibilityCard extends ConsumerWidget {
  final VoidCallback? onAppliedToFinancials;

  const LogisticsFeasibilityCard({
    super.key,
    this.onAppliedToFinancials,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';
    final evalAsync = ref.watch(supplierFreightEvaluationProvider);
    final selectedMode = ref.watch(selectedVehicleModeProvider);
    final trips = ref.watch(tripsPerMonthProvider);
    final appliedCost = ref.watch(appliedLogisticsCostProvider);

    return TactileCard(
      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5), width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHindi ? 'परिवहन एवं कच्चा माल लागत' : 'Logistics & Landed Cost Intelligence',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isHindi ? 'Mappls दूरी विश्लेषण • वास्तविक व्यय' : 'Mappls Distance Matrix • True Procurement Cost',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: isHindi ? 'स्मार्ट तुलना' : 'Distance Matrix',
                type: BadgeType.info,
              ),
            ],
          ),


          const SizedBox(height: 14),

          // Vehicle Mode Selector
          Text(
            isHindi ? 'परिवहन वाहन का चयन करें:' : 'Select Transport Vehicle Mode:',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: FreightVehicleMode.values.map((mode) {
                final isSelected = mode == selectedMode;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      '${mode.label} (₹${mode.defaultRatePerKm.toStringAsFixed(0)}/km)',
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceVariant,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    onSelected: (_) {
                      ref.read(selectedVehicleModeProvider.notifier).state = mode;
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Frequency Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isHindi ? 'मासिक चक्कर (Trips/Month):' : 'Procurement Trips / Month:',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [2, 4, 8].map((t) {
                  final isSel = t == trips;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: InkWell(
                      onTap: () {
                        ref.read(tripsPerMonthProvider.notifier).state = t;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.secondary : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$t',
                          style: TextStyle(
                            color: isSel ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const Divider(height: 20),

          // Evaluated Suppliers List
          evalAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(color: AppColors.secondary),
              ),
            ),
            error: (err, _) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${isHindi ? "विश्लेषण लोड करने में विफल" : "Failed to load logistics analysis"}: $err',
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
            data: (eval) {
              final results = eval.results;
              final recommended = eval.recommendedSupplier;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...results.map((item) => _buildSupplierComparisonRow(item, isHindi)),

                  const SizedBox(height: 12),

                  // Insight Callout
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
                        const Icon(Icons.insights_rounded, color: AppColors.success, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isHindi ? 'रणनीतिक वित्तीय अंतर्दृष्टि' : 'Strategic Landed Cost Insight',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isHindi ? eval.insightSummaryHi : eval.insightSummaryEn,
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Action to Apply Freight Cost to Financial Engine
                  if (recommended != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(
                          appliedCost > 0 ? Icons.check_circle_rounded : Icons.add_chart_rounded,
                          size: 18,
                        ),
                        label: Text(
                          appliedCost > 0
                              ? (isHindi
                                  ? 'लागत जोड़ी गई: ₹${appliedCost.toStringAsFixed(0)}/माह'
                                  : 'Freight Cost Applied: ₹${appliedCost.toStringAsFixed(0)}/mo')
                              : (isHindi
                                  ? 'वित्तीय मॉडल में ₹${recommended.monthlyFreightTotal.toStringAsFixed(0)}/माह ढुलाई जोड़ें'
                                  : 'Add ₹${recommended.monthlyFreightTotal.toStringAsFixed(0)}/mo Freight to Operating Costs'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appliedCost > 0 ? AppColors.success : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          // Update applied logistics cost provider
                          ref.read(appliedLogisticsCostProvider.notifier).state =
                              recommended.monthlyFreightTotal;

                          // Incorporate directly into active business monthlyOperatingCosts
                          final currentBiz = ref.read(selectedBusinessProvider);
                          ref.read(selectedBusinessProvider.notifier).selectBusiness(
                                currentBiz.copyWith(
                                  monthlyOperatingCosts: currentBiz.monthlyOperatingCosts +
                                      recommended.monthlyFreightTotal,
                                ),
                              );


                          if (onAppliedToFinancials != null) {
                            onAppliedToFinancials!();
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.success,
                              content: Text(
                                isHindi
                                    ? 'मासिक ढुलाई खर्च (₹${recommended.monthlyFreightTotal.toStringAsFixed(0)}) कार्यशील पूंजी में जोड़ा गया!'
                                    : 'Monthly freight cost (₹${recommended.monthlyFreightTotal.toStringAsFixed(0)}) added to operating costs!',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierComparisonRow(SupplierLandedCostItem item, bool isHindi) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: item.isRecommended ? AppColors.successBg.withValues(alpha: 0.5) : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.isRecommended ? AppColors.success : AppColors.border,
          width: item.isRecommended ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.supplierName,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isRecommended) ...[
                      const SizedBox(width: 6),
                      StatusBadge(
                        label: isHindi ? 'सर्वोत्तम विकल्प' : 'Best Value',
                        type: BadgeType.success,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.distanceKm} km • ~${item.durationMinutes} min via Mappls',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${item.effectiveLandedCost.toStringAsFixed(2)}/${item.unitName}',
                style: AppTypography.labelLarge.copyWith(
                  color: item.isRecommended ? AppColors.success : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Quoted: ₹${item.quotedPricePerUnit.toStringAsFixed(2)} (+₹${item.freightCostPerUnit.toStringAsFixed(2)})',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
