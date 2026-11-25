-- Run from a trusted backend; p_actor must be verified against Supabase Auth.
CREATE OR REPLACE FUNCTION horoof.advance_expired_turn(p_room_id bigint,p_actor uuid) RETURNS boolean LANGUAGE plpgsql SECURITY INVOKER SET search_path=pg_catalog,horoof AS $$
DECLARE r horoof.rooms%ROWTYPE; g horoof.games%ROWTYPE; prior_id bigint; next_user uuid;
BEGIN
SELECT * INTO r FROM horoof.rooms WHERE id=p_room_id FOR UPDATE;
IF NOT FOUND OR NOT EXISTS(SELECT 1 FROM horoof.room_players WHERE room_id=p_room_id AND user_id=p_actor) THEN RAISE EXCEPTION 'room unavailable' USING ERRCODE='P0001'; END IF;
IF r.status<>'playing' THEN RETURN false;END IF;
SELECT * INTO g FROM horoof.games WHERE room_id=p_room_id FOR UPDATE;
IF NOT FOUND OR g.winner_user IS NULL OR g.answer_deadline IS NULL OR g.answer_deadline>clock_timestamp() THEN RETURN false;END IF;
SELECT id INTO prior_id FROM horoof.buzzes WHERE room_id=p_room_id AND round_version=g.round_version AND user_id=g.winner_user;
SELECT user_id INTO next_user FROM horoof.buzzes WHERE room_id=p_room_id AND round_version=g.round_version AND id>prior_id ORDER BY id LIMIT 1;
UPDATE horoof.games SET winner_user=next_user,answer_deadline=CASE WHEN next_user IS NULL THEN NULL ELSE clock_timestamp()+interval '3 seconds' END,updated_at=clock_timestamp() WHERE room_id=p_room_id;
RETURN true;
END $$;
REVOKE ALL ON FUNCTION horoof.advance_expired_turn(bigint,uuid) FROM PUBLIC,anon,authenticated;
