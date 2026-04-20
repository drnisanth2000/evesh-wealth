/// Educational content for the 3-bucket strategy.
class BucketEducation {
  BucketEducation._();

  static const accumulationNotes = <String>[
    'Bucket 1 is a one-time setup (3-6 months expenses). Every SIP goes to Buckets 2 & 3.',
    'Core SIPs (75%): Index + Flexi cap. Satellite SIPs (25%): Mid/Small cap + Thematic.',
    "Don't pause SIPs in crashes — that's when you buy cheap.",
    'Principle preservation in Bucket 1 — no trading needed to meet short-term income.',
  ];

  static const distributionNotes = <String>[
    'Set up SWP only from Bucket 1 (liquid funds). Never force-sell Bucket 3 during a downturn.',
    'Even in a 40% crash, Bucket 1 covers 2-3 years — no need to panic.',
    'Refill Bucket 1 from Bucket 2 every 12-18 months. Refill Bucket 2 from Bucket 3 every 4-5 years.',
    'Take income generated from Bucket 2 to replenish Bucket 1 as it is spent.',
  ];

  static const generalNotes = <String>[
    'The 3-bucket strategy divides your portfolio by time horizon, so you never sell long-term assets during short-term downturns.',
    'Short-term movements in Bucket 3 are tolerable — it keeps pace with inflation over time.',
  ];

  static const bucketInstruments = <int, List<String>>{
    1: ['Savings account', 'Liquid funds', 'FD', 'Ultra-short duration', 'Money market'],
    2: ['Debt funds', 'Balanced Advantage', 'Hybrid funds', 'Gold', 'REITs'],
    3: ['Large cap equity', 'Mid cap equity', 'Small cap equity', 'Index funds', 'International', 'Direct stocks'],
  };

  static const bucketNames = <int, String>{
    1: 'Liquidity (0-2yr)',
    2: 'Stability (3-7yr)',
    3: 'Growth (7yr+)',
  };

  static const assetClassToBucket = <String, int>{
    'liquid': 1, 'debt': 1,
    'gold': 2, 'hybrid': 2, 'alternate': 2,
    'coreEquity': 3, 'satelliteEquity': 3,
  };

  static const accumulationRefillRules = <Map<String, dynamic>>[
    {'fromBucket': 2, 'toBucket': 1, 'trigger': 'Bucket 1 drops below 12 months expenses', 'frequency': 'Every 12-18 months', 'description': 'Transfer from Stability to Liquidity when short-term buffer runs low'},
    {'fromBucket': 3, 'toBucket': 2, 'trigger': 'Bucket 2 depleted below target', 'frequency': 'Every 4-5 years', 'description': 'Book partial Growth gains to refill Stability bucket'},
  ];

  static const distributionRefillRules = <Map<String, dynamic>>[
    {'fromBucket': 2, 'toBucket': 1, 'trigger': 'Bucket 1 drops below 12 months expenses', 'frequency': 'Every 12-18 months', 'description': 'Transfer from Stability to Liquidity for SWP source'},
    {'fromBucket': 3, 'toBucket': 2, 'trigger': 'Bucket 2 depleted below target', 'frequency': 'Every 4-5 years (only in up markets)', 'description': 'Book Growth gains to refill Stability — never force-sell in a downturn'},
  ];

  static List<String> notesForScenario(String scenario) {
    final specific = scenario == 'distribution' ? distributionNotes : accumulationNotes;
    return [...specific, ...generalNotes];
  }
}
