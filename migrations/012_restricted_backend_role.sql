-- Non-login group for the trusted API server, not for browsers.
-- RLS below grants this backend role access to all HOROOF rows; user-level
-- isolation remains the responsibility of the application. Never expose its
-- credentials, and do not treat these policies as per-user database isolation.
CREATE ROLE horoof_backend NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
GRANT USAGE ON SCHEMA horoof TO horoof_backend;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA horoof TO horoof_backend;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA horoof TO horoof_backend;
GRANT EXECUTE ON FUNCTION horoof.select_cell(bigint,uuid,integer),horoof.claim_buzzer(bigint,uuid),horoof.submit_answer(bigint,uuid,text),horoof.advance_expired_turn(bigint,uuid),horoof.normalize_answer(text),horoof.has_path(jsonb,text) TO horoof_backend;
DO $migration$
DECLARE t record;
BEGIN
 FOR t IN SELECT tablename FROM pg_tables WHERE schemaname='horoof' LOOP
   EXECUTE format('CREATE POLICY horoof_backend_access ON horoof.%I FOR ALL TO horoof_backend USING (true) WITH CHECK (true)',t.tablename);
 END LOOP;
END
$migration$;
