import 'package:flutter/material.dart';

import '../../widgets/discogs_setup/onboarding_carousel.dart';
import 'discogs_setup_strings.dart';

class DiscogsOnboardingImages {
  static const String step1 = 'assets/images/setup/discogs_create_account.png';

  static const String step2En = 'assets/images/setup/generate_token_eng.png';
  static const String step2Fr = 'assets/images/setup/generate_token_fr.png';

  static const String step3En = 'assets/images/setup/copy_token_eng.jpeg';
  static const String step3Fr = 'assets/images/setup/copy_token_fr.jpeg';

  static String step2(bool isFrench) => isFrench ? step2Fr : step2En;
  static String step3(bool isFrench) => isFrench ? step3Fr : step3En;

  static List<String> otherLanguage(bool isFrench) =>
      isFrench ? [step2En, step3En] : [step2Fr, step3Fr];
}

List<OnboardingStep> buildDiscogsOnboardingSteps(DiscogsSetupStrings strings) {
  return [
    OnboardingStep(
      title: strings.step1Title,
      description: strings.step1Description,
      imageUrl: DiscogsOnboardingImages.step1,
      imagePosition: OnboardingImagePosition.left,
      imageWidth: 100,
      imageHeight: 170,
      cardWidth: 270,
      cardHeight: 200,
      cardPadding: const EdgeInsets.all(14),
    ),
    OnboardingStep(
      title: strings.step2Title,
      description: strings.step2Description,
      imageUrl: DiscogsOnboardingImages.step2(strings.isFrench),
      imagePosition: OnboardingImagePosition.right,
      imageHeight: 115,
      imageWidth: 165,
      cardWidth: 345,
      cardHeight: 145,
      cardPadding: const EdgeInsets.all(12),
    ),
    OnboardingStep(
      title: strings.step3Title,
      description: strings.step3Description,
      imageUrl: DiscogsOnboardingImages.step3(strings.isFrench),
      imagePosition: OnboardingImagePosition.below,
      imageHeight: 80,
      cardWidth: 230,
      cardHeight: 210,
      cardPadding: const EdgeInsets.all(14),
    ),
    OnboardingStep(
      title: strings.step4Title,
      description: strings.step4Description,
      cardHeight: 100,
      cardWidth: 280,
      cardPadding: const EdgeInsets.all(16),
    ),
  ];
}