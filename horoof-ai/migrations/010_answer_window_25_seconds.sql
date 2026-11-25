-- Update the initial buzzer and both queued-player handoff paths.
DO $migration$
DECLARE fn regprocedure; definition text; updated text; changed int;
BEGIN
 FOREACH fn IN ARRAY ARRAY['horoof.claim_buzzer(bigint,uuid)'::regprocedure,'horoof.submit_answer(bigint,uuid,text)'::regprocedure,'horoof.advance_expired_turn(bigint,uuid)'::regprocedure] LOOP
   definition := pg_get_functiondef(fn);
   changed := (length(definition)-length(replace(definition, $$interval '3 seconds'$$, ''))) / length($$interval '3 seconds'$$);
   IF (fn::text LIKE '%claim_buzzer%' AND changed <> 2) OR (fn::text NOT LIKE '%claim_buzzer%' AND changed <> 1) THEN
     RAISE EXCEPTION 'Unexpected answer-window definition for %',fn;
   END IF;
   updated := replace(definition, $$interval '3 seconds'$$, $$interval '25 seconds'$$);
   EXECUTE updated;
 END LOOP;
END
$migration$;
