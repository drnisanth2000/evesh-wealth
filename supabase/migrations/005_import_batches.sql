-- ─────────────────────────────────────────────────────────────────────────────
-- Migration 005: import_batches table
-- Tracks each MF Central / CAS upload attempt for audit and retry purposes.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS import_batches (
  id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id        UUID          NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  file_name       TEXT,
  status          TEXT          NOT NULL DEFAULT 'processing'
                                CHECK (status IN ('processing', 'completed', 'partial', 'failed')),
  rows_parsed     INT           DEFAULT 0,
  rows_inserted   INT           DEFAULT 0,
  rows_duplicate  INT           DEFAULT 0,
  rows_error      INT           DEFAULT 0,
  error_details   JSONB,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  completed_at    TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_import_batches_owner
  ON import_batches(owner_id, created_at DESC);

-- RLS
ALTER TABLE import_batches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own import batches"
  ON import_batches FOR SELECT
  USING (owner_id = auth.uid());

CREATE POLICY "Users can insert their own import batches"
  ON import_batches FOR INSERT
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Users can update their own import batches"
  ON import_batches FOR UPDATE
  USING (owner_id = auth.uid());

-- Service role can update batch status from Edge Functions
CREATE POLICY "Service role can manage import batches"
  ON import_batches FOR ALL
  USING (auth.role() = 'service_role');
