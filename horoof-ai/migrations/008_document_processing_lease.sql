-- Lease and generation token allow a user to recover serverless work interrupted
-- by request termination without allowing a stale worker to overwrite a retry.
ALTER TABLE horoof.documents ADD COLUMN processing_token uuid, ADD COLUMN processing_started_at timestamptz;
