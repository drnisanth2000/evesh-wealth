// Reads out/amfi_categories.json and writes
// ../../lib/core/constants/amfi_category.g.dart with an enum + extension.
//
// Run: `npx tsx gen_dart.ts`

import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUT_DIR = join(__dirname, "out");
const DART_PATH = join(__dirname, "..", "..", "lib", "core", "constants", "amfi_category.g.dart");

interface Cat {
  id: string;
  super_category: string;
  name: string;
  tier1_benchmark: string;
  tier2_benchmark: string;
  default_term: string;
  default_asset_class: string;
  default_tax_category: string;
}

function camelize(snake: string): string {
  return snake
    .split("_")
    .map((w, i) =>
      i === 0 ? w : w.charAt(0).toUpperCase() + w.slice(1).toLowerCase(),
    )
    .join("");
}

function dartString(s: string): string {
  return "'" + s.replace(/\\/g, "\\\\").replace(/'/g, "\\'") + "'";
}

function main() {
  const cats: Cat[] = JSON.parse(
    readFileSync(join(OUT_DIR, "amfi_categories.json"), "utf8"),
  );

  const lines: string[] = [
    "// GENERATED — do not edit by hand. Run tools/amfi_scraper/gen_dart.ts",
    "",
    "import 'asset_classes.dart';",
    "import '../../data/models/goal_model.dart' show GoalTerm;",
    "",
    "enum AmfiCategory {",
  ];
  for (const c of cats) {
    lines.push("  " + camelize(c.id) + ",");
  }
  lines.push("}");
  lines.push("");

  lines.push("extension AmfiCategoryX on AmfiCategory {");
  lines.push("  String get id {");
  lines.push("    switch (this) {");
  for (const c of cats) {
    lines.push(`      case AmfiCategory.${camelize(c.id)}: return ${dartString(c.id)};`);
  }
  lines.push("    }");
  lines.push("  }");
  lines.push("");

  lines.push("  String get superCategory {");
  lines.push("    switch (this) {");
  for (const c of cats) {
    lines.push(`      case AmfiCategory.${camelize(c.id)}: return ${dartString(c.super_category)};`);
  }
  lines.push("    }");
  lines.push("  }");
  lines.push("");

  lines.push("  String get displayName {");
  lines.push("    switch (this) {");
  for (const c of cats) {
    lines.push(`      case AmfiCategory.${camelize(c.id)}: return ${dartString(c.name)};`);
  }
  lines.push("    }");
  lines.push("  }");
  lines.push("");

  lines.push("  String get tier1Benchmark {");
  lines.push("    switch (this) {");
  for (const c of cats) {
    lines.push(`      case AmfiCategory.${camelize(c.id)}: return ${dartString(c.tier1_benchmark)};`);
  }
  lines.push("    }");
  lines.push("  }");
  lines.push("");

  lines.push("  String get tier2Benchmark {");
  lines.push("    switch (this) {");
  for (const c of cats) {
    lines.push(`      case AmfiCategory.${camelize(c.id)}: return ${dartString(c.tier2_benchmark)};`);
  }
  lines.push("    }");
  lines.push("  }");
  lines.push("");

  lines.push("  GoalTerm get defaultTerm {");
  lines.push("    switch (this) {");
  for (const c of cats) {
    lines.push(`      case AmfiCategory.${camelize(c.id)}: return GoalTerm.${c.default_term};`);
  }
  lines.push("    }");
  lines.push("  }");
  lines.push("");

  lines.push("  AssetClass get defaultAssetClass {");
  lines.push("    switch (this) {");
  for (const c of cats) {
    const v = c.default_asset_class.charAt(0).toLowerCase() + c.default_asset_class.slice(1);
    lines.push(`      case AmfiCategory.${camelize(c.id)}: return AssetClass.${v};`);
  }
  lines.push("    }");
  lines.push("  }");
  lines.push("");

  lines.push("  TaxCategory get defaultTaxCategory {");
  lines.push("    switch (this) {");
  for (const c of cats) {
    lines.push(`      case AmfiCategory.${camelize(c.id)}: return TaxCategory.${c.default_tax_category};`);
  }
  lines.push("    }");
  lines.push("  }");
  lines.push("");

  lines.push("  static AmfiCategory? fromId(String id) {");
  lines.push("    for (final v in AmfiCategory.values) {");
  lines.push("      if (v.id == id) return v;");
  lines.push("    }");
  lines.push("    return null;");
  lines.push("  }");
  lines.push("}");
  lines.push("");

  writeFileSync(DART_PATH, lines.join("\n"));
  console.log(`Wrote ${DART_PATH}`);
}

main();
