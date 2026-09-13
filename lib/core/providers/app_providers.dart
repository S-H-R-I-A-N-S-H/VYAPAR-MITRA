import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';
import '../network/api_client.dart';

/// Provider for authentication session and token management.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Provider for the global ApiClient instance.
/// Automatically injects the active authentication token from authProvider.
final apiClientProvider = Provider<ApiClient>((ref) {
  final authState = ref.watch(authProvider);
  final client = ApiClient(authToken: authState.token);
  ref.onDispose(() => client.close());
  return client;
});

/// StateNotifier to manage the user's selected language.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en'));

  void setLocale(String languageCode) {
    state = Locale(languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

/// Holds the active business profile information entered by the entrepreneur.
class BusinessProfileState {
  final String? profileId;
  final String? fullName;
  final String? phone;
  final String district;
  final String block;
  final String stateName;
  final double personalCapital;
  final String businessIdea;
  final String startingPosition; // specific_idea, general_domain, explore
  final String socialCategory; // general, obc, sc, st, woman

  const BusinessProfileState({
    this.profileId,
    this.fullName,
    this.phone,
    this.district = 'Indore',
    this.block = 'Sanwer',
    this.stateName = 'Madhya Pradesh',
    this.personalCapital = 60000.0,
    this.businessIdea = 'Cold-Press Mustard Oil Mill',
    this.startingPosition = 'specific_idea',
    this.socialCategory = 'general',
  });

  BusinessProfileState copyWith({
    String? profileId,
    String? fullName,
    String? phone,
    String? district,
    String? block,
    String? stateName,
    double? personalCapital,
    String? businessIdea,
    String? startingPosition,
    String? socialCategory,
  }) {
    return BusinessProfileState(
      profileId: profileId ?? this.profileId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      district: district ?? this.district,
      block: block ?? this.block,
      stateName: stateName ?? this.stateName,
      personalCapital: personalCapital ?? this.personalCapital,
      businessIdea: businessIdea ?? this.businessIdea,
      startingPosition: startingPosition ?? this.startingPosition,
      socialCategory: socialCategory ?? this.socialCategory,
    );
  }
}

class BusinessProfileNotifier extends StateNotifier<BusinessProfileState> {
  BusinessProfileNotifier() : super(const BusinessProfileState());

  void updateProfile(BusinessProfileState updated) {
    state = updated;
  }

  void setProfileId(String id) {
    state = state.copyWith(profileId: id);
  }

  void setCapital(double amount) {
    state = state.copyWith(personalCapital: amount);
  }

  void setIdea(String idea) {
    state = state.copyWith(businessIdea: idea);
  }
}

final businessProfileProvider =
    StateNotifierProvider<BusinessProfileNotifier, BusinessProfileState>((ref) {
  return BusinessProfileNotifier();
});

/// Holds the selected business opportunity and active business UUID.
class SelectedBusinessState {
  final String? businessId;
  final String title;
  final String domain;
  final double estimatedCapital;
  final double monthlyRevenue;
  final double monthlyOperatingCosts;
  final double monthlyEmi;
  final double netCashMonthly;
  final String status; // IDEA, VALIDATING, PLANNED
  final String schemeEligible;

  const SelectedBusinessState({
    this.businessId,
    this.title = 'Cold-Press Mustard Oil Mill',
    this.domain = 'Agri-Processing & Food Products',
    this.estimatedCapital = 180000.0,
    this.monthlyRevenue = 62000.0,
    this.monthlyOperatingCosts = 33500.0,
    this.monthlyEmi = 3100.0,
    this.netCashMonthly = 25400.0,
    this.status = 'IDEA',
    this.schemeEligible = '35% PMEGP Subsidy + Mudra Shishu',
  });

  SelectedBusinessState copyWith({
    String? businessId,
    String? title,
    String? domain,
    double? estimatedCapital,
    double? monthlyRevenue,
    double? monthlyOperatingCosts,
    double? monthlyEmi,
    double? netCashMonthly,
    String? status,
    String? schemeEligible,
  }) {
    return SelectedBusinessState(
      businessId: businessId ?? this.businessId,
      title: title ?? this.title,
      domain: domain ?? this.domain,
      estimatedCapital: estimatedCapital ?? this.estimatedCapital,
      monthlyRevenue: monthlyRevenue ?? this.monthlyRevenue,
      monthlyOperatingCosts: monthlyOperatingCosts ?? this.monthlyOperatingCosts,
      monthlyEmi: monthlyEmi ?? this.monthlyEmi,
      netCashMonthly: netCashMonthly ?? this.netCashMonthly,
      status: status ?? this.status,
      schemeEligible: schemeEligible ?? this.schemeEligible,
    );
  }
}

class SelectedBusinessNotifier extends StateNotifier<SelectedBusinessState> {
  SelectedBusinessNotifier() : super(const SelectedBusinessState());

  void selectBusiness(SelectedBusinessState business) {
    state = business;
  }

  void setBusinessId(String id) {
    state = state.copyWith(businessId: id);
  }

  void setStatus(String newStatus) {
    state = state.copyWith(status: newStatus);
  }
}

final selectedBusinessProvider =
    StateNotifierProvider<SelectedBusinessNotifier, SelectedBusinessState>((ref) {
  return SelectedBusinessNotifier();
});
