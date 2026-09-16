import 'package:flutter/material.dart';
import '../../validation/screens/validation_dashboard_screen.dart';
import '../../../shared/widgets/status_badge.dart';

/// Representation of a single research pillar in the 6-pillar validation framework.
class ResearchPillar {
  final String pillar;
  final String badgeText;
  final String badgeType; // success, warning, info, error
  final String description;
  final double confidence;
  final String source;

  const ResearchPillar({
    required this.pillar,
    required this.badgeText,
    required this.badgeType,
    required this.description,
    this.confidence = 0.85,
    this.source = 'Google Search Grounding & District Mandi Assessment',
  });

  factory ResearchPillar.fromJson(Map<String, dynamic> json) {
    return ResearchPillar(
      pillar: json['pillar'] as String? ?? 'Market Analysis',
      badgeText: json['badge_text'] as String? ?? 'Verified',
      badgeType: (json['badge_type'] as String? ?? 'info').toLowerCase(),
      description: json['description'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.85,
      source: json['source'] as String? ?? 'Market Signals',
    );
  }

  Map<String, dynamic> toJson() => {
        'pillar': pillar,
        'badge_text': badgeText,
        'badge_type': badgeType,
        'description': description,
        'confidence': confidence,
        'source': source,
      };

  /// Converts this pillar into the UI PillarItem required by ValidationDashboardScreen
  PillarItem toPillarItem() {
    BadgeType bType;
    switch (badgeType) {
      case 'success':
        bType = BadgeType.success;
        break;
      case 'warning':
      case 'error':
        bType = BadgeType.warning;
        break;
      case 'info':
      default:
        bType = BadgeType.info;
        break;
    }

    IconData icon;
    final pLower = pillar.toLowerCase();
    if (pLower.contains('customer') || pLower.contains('demand')) {
      icon = Icons.shopping_bag_rounded;
    } else if (pLower.contains('compet')) {
      icon = Icons.storefront_rounded;
    } else if (pLower.contains('price') || pLower.contains('margin')) {
      icon = Icons.monetization_on_rounded;
    } else if (pLower.contains('raw') || pLower.contains('material') || pLower.contains('supply')) {
      icon = Icons.agriculture_rounded;
    } else if (pLower.contains('regulat') || pLower.contains('license') || pLower.contains('complian')) {
      icon = Icons.verified_rounded;
    } else if (pLower.contains('scheme') || pLower.contains('subsid') || pLower.contains('govt') || pLower.contains('govern')) {
      icon = Icons.account_balance_rounded;
    } else {
      icon = Icons.analytics_rounded;
    }

    return PillarItem(
      title: pillar,
      badgeText: badgeText,
      badgeType: bType,
      description: description,
      icon: icon,
    );
  }
}

/// Discrepancy detected between secondary grounded search and field data
class ResearchDiscrepancy {
  final String parameter;
  final String secondarySource;
  final String fieldSource;
  final double discrepancyPct;
  final String impact;

  const ResearchDiscrepancy({
    required this.parameter,
    required this.secondarySource,
    required this.fieldSource,
    required this.discrepancyPct,
    required this.impact,
  });

  factory ResearchDiscrepancy.fromJson(Map<String, dynamic> json) {
    return ResearchDiscrepancy(
      parameter: json['parameter'] as String? ?? 'Pricing Metric',
      secondarySource: json['secondary_source'] as String? ?? 'District Record',
      fieldSource: json['field_source'] as String? ?? 'Local Survey',
      discrepancyPct: (json['discrepancy_pct'] as num?)?.toDouble() ?? 0.0,
      impact: json['impact'] as String? ?? 'Low',
    );
  }
}

/// Web-grounded authoritative source citation from Gemini research
class ResearchGroundingSource {
  final String title;
  final String url;

  const ResearchGroundingSource({
    required this.title,
    required this.url,
  });

  factory ResearchGroundingSource.fromJson(Map<String, dynamic> json) {
    return ResearchGroundingSource(
      title: json['title'] as String? ?? 'Web Citation',
      url: json['url'] as String? ?? '',
    );
  }
}

/// Complete synthesized secondary research outcome
class ResearchSynthesisResult {
  final String projectId;
  final String businessName;
  final String district;
  final String state;
  final String overallStatus;
  final String statusColor;
  final String summary;
  final int evidenceCount;
  final int dataPointsCollected;
  final List<ResearchPillar> pillars;
  final List<ResearchDiscrepancy> discrepancies;
  final List<ResearchGroundingSource> groundingSources;
  final DateTime? createdAt;

  const ResearchSynthesisResult({
    required this.projectId,
    required this.businessName,
    required this.district,
    required this.state,
    required this.overallStatus,
    required this.statusColor,
    required this.summary,
    required this.evidenceCount,
    required this.dataPointsCollected,
    required this.pillars,
    this.discrepancies = const [],
    this.groundingSources = const [],
    this.createdAt,
  });

  factory ResearchSynthesisResult.fromJson(Map<String, dynamic> json) {
    final synthesis = json['synthesis'] as Map<String, dynamic>? ?? {};
    final loc = json['location'] as Map<String, dynamic>? ?? {};

    final rawPillars = synthesis['pillars'] as List<dynamic>? ?? [];
    final pillarsList = rawPillars
        .map((p) => ResearchPillar.fromJson(p as Map<String, dynamic>))
        .toList();

    final rawDiscrepancies = synthesis['discrepancies'] as List<dynamic>? ?? [];
    final discrepanciesList = rawDiscrepancies
        .map((d) => ResearchDiscrepancy.fromJson(d as Map<String, dynamic>))
        .toList();

    final rawSources = synthesis['grounding_sources'] as List<dynamic>? ?? [];
    final sourcesList = rawSources
        .map((s) => ResearchGroundingSource.fromJson(s as Map<String, dynamic>))
        .toList();

    return ResearchSynthesisResult(
      projectId: json['project_id'] as String? ?? '',
      businessName: json['business_name'] as String? ?? '',
      district: loc['district'] as String? ?? 'Indore',
      state: loc['state'] as String? ?? 'Madhya Pradesh',
      overallStatus: synthesis['overall_status'] as String? ?? 'Promising with Conditions',
      statusColor: (synthesis['status_color'] as String? ?? 'success').toLowerCase(),
      summary: synthesis['summary'] as String? ?? 'Analysis completed across 6 validation dimensions.',
      evidenceCount: (json['evidence_count'] as num?)?.toInt() ?? pillarsList.length,
      dataPointsCollected: (json['data_points_collected'] as num?)?.toInt() ?? 14,
      pillars: pillarsList,
      discrepancies: discrepanciesList,
      groundingSources: sourcesList,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }
}
