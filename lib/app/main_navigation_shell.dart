import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/app_providers.dart';
import '../core/theme/app_colors.dart';
import '../features/analyzer/screens/analyzer_screen.dart';
import '../features/finance/screens/finance_home_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/learn/screens/learn_screen.dart';

/// Provider for managing the active index of the persistent bottom navigation bar.
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// Screen: MainNavigationShell
/// Conforms to SIH 26091 App Structure (Section 3 & Section 12)
/// Persistent 4-tab bottom navigation: Home | Analyzer | Finance | Learn
/// Active ONLY after onboarding completes.
class MainNavigationShell extends ConsumerWidget {
  final int initialIndex;

  const MainNavigationShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';

    final List<Widget> pages = const [
      HomeScreen(),
      AnalyzerScreen(),
      FinanceHomeScreen(),
      LearnScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (idx) {
              ref.read(bottomNavIndexProvider.notifier).state = idx;
            },
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            height: 64,
            elevation: 0,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined, color: AppColors.textSecondary),
                selectedIcon: const Icon(Icons.home_rounded, color: AppColors.primary),
                label: isHindi ? 'होम' : 'Home',
              ),
              NavigationDestination(
                icon: const Icon(Icons.analytics_outlined, color: AppColors.textSecondary),
                selectedIcon: const Icon(Icons.analytics_rounded, color: AppColors.primary),
                label: isHindi ? 'विश्लेषक' : 'Analyzer',
              ),
              NavigationDestination(
                icon: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.textSecondary),
                selectedIcon: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
                label: isHindi ? 'वित्त' : 'Finance',
              ),
              NavigationDestination(
                icon: const Icon(Icons.menu_book_outlined, color: AppColors.textSecondary),
                selectedIcon: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                label: isHindi ? 'ज्ञान' : 'Learn',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
