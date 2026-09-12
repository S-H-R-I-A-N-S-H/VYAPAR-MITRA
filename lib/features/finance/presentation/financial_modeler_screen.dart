import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/metric_tile.dart';
import '../../../shared/widgets/primary_button.dart';

class FinancialModelerScreen extends StatefulWidget {
  const FinancialModelerScreen({super.key});

  @override
  State<FinancialModelerScreen> createState() => _FinancialModelerScreenState();
}

class _FinancialModelerScreenState extends State<FinancialModelerScreen> {
  double _projectCost = 250000;
  double _ownCapital = 50000;

  @override
  Widget build(BuildContext context) {
    final loanNeeded = (_projectCost - _ownCapital).clamp(0.0, _projectCost);
    // Simple 9.5% 3-year estimation for instant UI feedback
    final estMonthlyEmi = (loanNeeded > 0) ? (loanNeeded * 0.032) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Financial Modeler'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Project Cost & Capital', style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Total Project Cost: ${CurrencyFormatter.formatINR(_projectCost)}',
              style: AppTypography.bodyMedium,
            ),
            Slider(
              value: _projectCost,
              min: 50000,
              max: 2000000,
              divisions: 39,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _projectCost = val),
            ),
            const SizedBox(height: 12),
            Text(
              'Your Own Capital: ${CurrencyFormatter.formatINR(_ownCapital)}',
              style: AppTypography.bodyMedium,
            ),
            Slider(
              value: _ownCapital.clamp(0.0, _projectCost),
              min: 0,
              max: _projectCost,
              activeColor: AppColors.secondary,
              onChanged: (val) => setState(() => _ownCapital = val),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    label: 'Loan Required',
                    value: CurrencyFormatter.formatINR(loanNeeded),
                    subtitle: 'Debt sizing',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricTile(
                    label: 'Est. Monthly EMI',
                    value: CurrencyFormatter.formatINR(estMonthlyEmi),
                    valueColor: AppColors.primary,
                    subtitle: 'At 9.5% for 3 yrs',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'View Matched Schemes & Evidence →',
              onPressed: () {
                Navigator.pushNamed(context, '/evidence');
              },
            ),
          ],
        ),
      ),
    );
  }
}
