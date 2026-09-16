import 'package:flutter/material.dart';

/// Business Lifecycle Stages defined in the SIH 26091 App UI & Screen Specification
enum BusinessLifecycleStage {
  newOnboarding, // Complete profile + understand app -> Continue setup
  discover, // AI interview + opportunity discovery -> Continue discovery
  validate, // Research progress + missing evidence -> Complete next research task
  decide, // Recommendation + risks + confidence -> Review recommendation
  financePlanning, // Project cost + schemes + affordability -> Check affordability
  started, // AI Business Insights + performance -> View latest insight
  growth, // Targets + growth opportunities + financial capacity -> Analyze growth
}

/// Helper extension providing UI presentation metadata for each lifecycle stage.
extension BusinessLifecycleStageX on BusinessLifecycleStage {
  String get code {
    switch (this) {
      case BusinessLifecycleStage.newOnboarding:
        return 'new_onboarding';
      case BusinessLifecycleStage.discover:
        return 'discover';
      case BusinessLifecycleStage.validate:
        return 'validate';
      case BusinessLifecycleStage.decide:
        return 'decide';
      case BusinessLifecycleStage.financePlanning:
        return 'finance_planning';
      case BusinessLifecycleStage.started:
        return 'started';
      case BusinessLifecycleStage.growth:
        return 'growth';
    }
  }

  String getStageTag(bool isHindi) {
    switch (this) {
      case BusinessLifecycleStage.newOnboarding:
        return isHindi ? 'शुरुआत चरण' : 'ONBOARDING';
      case BusinessLifecycleStage.discover:
        return isHindi ? 'पहचान चरण' : 'DISCOVER';
      case BusinessLifecycleStage.validate:
        return isHindi ? 'सत्यापन चरण' : 'VALIDATE';
      case BusinessLifecycleStage.decide:
        return isHindi ? 'निर्णय चरण' : 'DECIDE';
      case BusinessLifecycleStage.financePlanning:
        return isHindi ? 'वित्त योजना' : 'FINANCE';
      case BusinessLifecycleStage.started:
        return isHindi ? 'संचालन चरण' : 'OPERATING';
      case BusinessLifecycleStage.growth:
        return isHindi ? 'विस्तार चरण' : 'GROWTH';
    }
  }

  String getTitle(bool isHindi) {
    switch (this) {
      case BusinessLifecycleStage.newOnboarding:
        return isHindi
            ? 'प्रोफ़ाइल पूरा करें व ऐप समझें'
            : 'Complete Profile & Get Started';
      case BusinessLifecycleStage.discover:
        return isHindi
            ? 'एआई सलाहकार से बात करें व अवसर खोजें'
            : 'AI Interview & Opportunity Discovery';
      case BusinessLifecycleStage.validate:
        return isHindi
            ? 'जमीनी शोध पूरा करें व सबूत जुटाएं'
            : 'Field Research & Evidence Pipeline';
      case BusinessLifecycleStage.decide:
        return isHindi
            ? 'अंतिम सिफारिश व जोखिम समीक्षा करें'
            : 'Final Recommendation & Confidence';
      case BusinessLifecycleStage.financePlanning:
        return isHindi
            ? 'परियोजना लागत, योजनाएं व कर्ज क्षमता'
            : 'Project Cost, Schemes & Affordability';
      case BusinessLifecycleStage.started:
        return isHindi
            ? 'एआई व्यापार अंतर्दृष्टि व दैनिक रिकॉर्ड'
            : 'AI Business Insights & Daily Logbook';
      case BusinessLifecycleStage.growth:
        return isHindi
            ? 'व्यापार विस्तार लक्ष्य व नए अवसर'
            : 'Expansion Targets & Growth Capacity';
    }
  }

  String getWhyItMatters(bool isHindi) {
    switch (this) {
      case BusinessLifecycleStage.newOnboarding:
        return isHindi
            ? 'सटीक जानकारी देने से आपके क्षेत्र के अनुसार सही योजनाएं और अवसर मिलेंगे।'
            : 'Sharing your local context ensures tailored schemes and realistic market projections.';
      case BusinessLifecycleStage.discover:
        return isHindi
            ? 'अपने हुनर व संसाधनों को स्थानीय मांग से मिलाकर सर्वोत्तम अवसर पहचानें।'
            : 'Match your practical skills with hyper-local catchment demand for minimum risk.';
      case BusinessLifecycleStage.validate:
        return isHindi
            ? 'मंडी भाव व स्थानीय प्रतियोगियों की वास्तविक जांच से गलत निर्णय से बचें।'
            : 'Verify mandi pricing and local competition on the ground before investing capital.';
      case BusinessLifecycleStage.decide:
        return isHindi
            ? 'साक्ष्यों और व्यवहार्यता स्कोर के आधार पर ठोस व्यापारिक निर्णय लें।'
            : 'Make an evidence-backed decision with confidence scores, SWOT, and risk buffers.';
      case BusinessLifecycleStage.financePlanning:
        return isHindi
            ? 'सुनिश्चित करें कि ऋण की मासिक किस्त (EMI) व्यापार के शुद्ध लाभ से सुरक्षित भर सके।'
            : 'Ensure projected business cash flow can safely support repayments without distress.';
      case BusinessLifecycleStage.started:
        return isHindi
            ? 'दैनिक बिक्री और खर्च दर्ज करें ताकि एआई अनुमान और वास्तविकता की तुलना कर सके।'
            : 'Log actual sales and purchases to compare real performance against projections.';
      case BusinessLifecycleStage.growth:
        return isHindi
            ? 'वित्तीय मजबूती व बाजार स्थिति को देखते हुए सुरक्षित विस्तार का समय चुनें।'
            : 'Evaluate whether you can afford expansion and identify the best new territory.';
    }
  }

  String getPrimaryCtaLabel(bool isHindi) {
    switch (this) {
      case BusinessLifecycleStage.newOnboarding:
        return isHindi ? 'सेटअप आगे बढ़ाएं →' : 'Continue Setup →';
      case BusinessLifecycleStage.discover:
        return isHindi ? 'खोज जारी रखें • AI साक्षात्कार →' : 'Continue Discovery →';
      case BusinessLifecycleStage.validate:
        return isHindi ? 'अगला शोध कार्य पूरा करें →' : 'Complete Next Research Task →';
      case BusinessLifecycleStage.decide:
        return isHindi ? 'सिफारिश व योजना देखें →' : 'Review Recommendation →';
      case BusinessLifecycleStage.financePlanning:
        return isHindi ? 'कर्ज क्षमता व सब्सिडी जांचें →' : 'Check Affordability →';
      case BusinessLifecycleStage.started:
        return isHindi ? 'नवीनतम अंतर्दृष्टि देखें →' : 'View Latest Insight →';
      case BusinessLifecycleStage.growth:
        return isHindi ? 'विकास व विस्तार विश्लेषण →' : 'Analyze Growth →';
    }
  }

  String getPrimaryCtaRoute() {
    switch (this) {
      case BusinessLifecycleStage.newOnboarding:
        return '/profile';
      case BusinessLifecycleStage.discover:
        return '/interview';
      case BusinessLifecycleStage.validate:
        return '/research-progress';
      case BusinessLifecycleStage.decide:
        return '/action-plan';
      case BusinessLifecycleStage.financePlanning:
        return '/finance-modeler';
      case BusinessLifecycleStage.started:
        return '/validation-dashboard';
      case BusinessLifecycleStage.growth:
        return '/swot-analysis';
    }
  }

  double get progressValue {
    switch (this) {
      case BusinessLifecycleStage.newOnboarding:
        return 0.15;
      case BusinessLifecycleStage.discover:
        return 0.30;
      case BusinessLifecycleStage.validate:
        return 0.55;
      case BusinessLifecycleStage.decide:
        return 0.75;
      case BusinessLifecycleStage.financePlanning:
        return 0.90;
      case BusinessLifecycleStage.started:
        return 0.95;
      case BusinessLifecycleStage.growth:
        return 1.00;
    }
  }

  IconData get icon {
    switch (this) {
      case BusinessLifecycleStage.newOnboarding:
        return Icons.person_outline_rounded;
      case BusinessLifecycleStage.discover:
        return Icons.explore_rounded;
      case BusinessLifecycleStage.validate:
        return Icons.fact_check_rounded;
      case BusinessLifecycleStage.decide:
        return Icons.verified_rounded;
      case BusinessLifecycleStage.financePlanning:
        return Icons.account_balance_wallet_rounded;
      case BusinessLifecycleStage.started:
        return Icons.storefront_rounded;
      case BusinessLifecycleStage.growth:
        return Icons.trending_up_rounded;
    }
  }
}
