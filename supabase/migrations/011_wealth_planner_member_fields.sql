-- 011_wealth_planner_member_fields.sql
-- Adds financial profile fields for Wealth Planner retirement and allocation planning

ALTER TABLE family_members
  ADD COLUMN IF NOT EXISTS retirement_age INTEGER DEFAULT 60,
  ADD COLUMN IF NOT EXISTS life_expectancy INTEGER DEFAULT 85,
  ADD COLUMN IF NOT EXISTS monthly_expense NUMERIC(18,2),
  ADD COLUMN IF NOT EXISTS annual_expenses JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS income_type TEXT DEFAULT 'steady' CHECK (income_type IN ('steady', 'variable', 'mixed')),
  ADD COLUMN IF NOT EXISTS monthly_income NUMERIC(18,2),
  ADD COLUMN IF NOT EXISTS income_variability_pct NUMERIC(5,2),
  ADD COLUMN IF NOT EXISTS expected_increment_pct NUMERIC(5,2) DEFAULT 8.0,
  ADD COLUMN IF NOT EXISTS expected_lumpsums JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS risk_score_computed INTEGER;

-- Add priority and common-goal fields to goals table
ALTER TABLE goals
  ADD COLUMN IF NOT EXISTS priority INTEGER DEFAULT 4,
  ADD COLUMN IF NOT EXISTS is_common BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS goal_bucket TEXT DEFAULT 'long' CHECK (goal_bucket IN ('short', 'medium', 'long'));

-- Add allocation_policy JSONB to families for tiered sub-bucket targets
ALTER TABLE families
  ADD COLUMN IF NOT EXISTS allocation_policy JSONB;

COMMENT ON COLUMN family_members.annual_expenses IS 'JSON array: [{name, amount, frequency, include_in_retirement}]';
COMMENT ON COLUMN family_members.expected_lumpsums IS 'JSON array: [{amount, expected_date, received_date, confidence, source, horizon_years, linked_goal_id, deployment_strategy}]';
COMMENT ON COLUMN family_members.income_type IS 'steady = salaried, variable = business/freelance, mixed = both';
COMMENT ON COLUMN goals.priority IS '1=emergency, 2=retirement, 3=education, 4=lifestyle';
COMMENT ON COLUMN goals.goal_bucket IS 'short=0-3yr, medium=3-10yr, long=10yr+';
COMMENT ON COLUMN families.allocation_policy IS 'Tiered Core-Satellite sub-bucket target ranges JSON';
