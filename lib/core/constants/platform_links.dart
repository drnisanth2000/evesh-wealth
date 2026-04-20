// lib/core/constants/platform_links.dart

import 'package:flutter/material.dart';
import '../../domain/models/action_models.dart';

/// Configuration for each supported investment platform.
class PlatformConfig {
  final Platform platform;
  final String name;
  final IconData icon;
  final String baseUrl;
  final bool supportsDeepLink;

  const PlatformConfig({
    required this.platform,
    required this.name,
    required this.icon,
    required this.baseUrl,
    this.supportsDeepLink = false,
  });
}

/// All supported platforms and their URL patterns.
class PlatformLinks {
  PlatformLinks._();

  static const platforms = <Platform, PlatformConfig>{
    Platform.mfCentral: PlatformConfig(
      platform: Platform.mfCentral,
      name: 'MFCentral',
      icon: Icons.account_balance,
      baseUrl: 'https://www.mfcentral.com/',
    ),
    Platform.groww: PlatformConfig(
      platform: Platform.groww,
      name: 'Groww',
      icon: Icons.trending_up,
      baseUrl: 'https://groww.in/mutual-funds/',
    ),
    Platform.kuvera: PlatformConfig(
      platform: Platform.kuvera,
      name: 'Kuvera',
      icon: Icons.pie_chart,
      baseUrl: 'https://kuvera.in/explore/',
    ),
    Platform.zerodha: PlatformConfig(
      platform: Platform.zerodha,
      name: 'Zerodha Coin',
      icon: Icons.currency_rupee,
      baseUrl: 'https://coin.zerodha.com/',
    ),
    Platform.indmoney: PlatformConfig(
      platform: Platform.indmoney,
      name: 'INDmoney',
      icon: Icons.account_balance_wallet,
      baseUrl: 'https://www.indmoney.com/mutual-funds/',
    ),
  };

  /// Generate platform links for a given action (buy/sell).
  /// For now all links are generic (platform homepage).
  /// When APIs become available, deep links will include fund identifiers.
  static List<PlatformLink> linksForAction({int? amfiCode}) {
    return platforms.values.map((config) {
      return PlatformLink(
        platform: config.platform,
        url: config.baseUrl,
        label: 'Open on ${config.name}',
      );
    }).toList();
  }
}
