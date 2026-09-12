import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/conflict_banner.dart';

class EvidenceDashboardScreen extends StatelessWidget {
  const EvidenceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evidence & Validation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ground-Truth vs Online Research', style: AppTypography.titleLarge),
            const SizedBox(height: 12),
            const ConflictBanner(
              title: 'Market Demand Discrepancy Detected',
              description:
                  'Secondary government reports indicate 30% regional dairy deficit, but local village survey (25 shops) reports surplus uncollected milk in the village.',
            ),
            const SizedBox(height: 20),
            Text('Traceable Evidence Records', style: AppTypography.titleLarge),
            const SizedBox(height: 12),
            _buildEvidenceCard(
              source: 'District Industrial Centre (DIC) Report 2024',
              claim: 'Average village milk collection potential: 450 Litres/day.',
              type: 'GOVERNMENT',
              confidence: '85% Confidence',
            ),
            const SizedBox(height: 12),
            _buildEvidenceCard(
              source: 'In-App Primary Field Survey (25 Respondents)',
              claim: '72% of farmers sell milk at ₹28/L; seek reliable collection partner.',
              type: 'LOCAL_SURVEY',
              confidence: '92% Confidence',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceCard({
    required String source,
    required String claim,
    required String type,
    required String confidence,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    type,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  confidence,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(claim, style: AppTypography.bodyLarge),
            const SizedBox(height: 8),
            Text(
              'Source: $source',
              style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
