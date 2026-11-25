-- Trusted backend only. The backend must validate the authenticated user and
-- pass their verified UUID, never an untrusted user ID from a request body.
CREATE OR REPLACE FUNCTION horoof.select_cell(p_room_id bigint, p_actor uuid, p_cell integer) RETURNS bigint LANGUAGE plpgsql SECURITY INVOKER SET search_path = pg_catalog, horoof AS $$
DECLARE r horoof.rooms%ROWTYPE; g horoof.games%ROWTYPE; actor_team text; chosen_letter text; qid bigint;
BEGIN
 SELECT * INTO r FROM horoof.rooms WHERE id=p_room_id FOR UPDATE;
 IF NOT FOUND OR r.status <> 'playing' THEN RAISE EXCEPTION 'game unavailable' USING ERRCODE='P0001'; END IF;
 SELECT team INTO actor_team FROM horoof.room_players WHERE room_id=p_room_id AND user_id=p_actor;
 IF NOT FOUND THEN RAISE EXCEPTION 'not a participant' USING ERRCODE='P0001'; END IF;
 SELECT * INTO g FROM horoof.games WHERE room_id=p_room_id FOR UPDATE;
 IF NOT FOUND OR g.active_cell IS NOT NULL OR g.result IS NOT NULL OR p_cell IS NULL OR p_cell<0 OR p_cell>24 THEN RAISE EXCEPTION 'cell unavailable' USING ERRCODE='P0001'; END IF;
 IF g.turn_team IS NOT NULL AND g.turn_team<>actor_team THEN RAISE EXCEPTION 'not your team turn' USING ERRCODE='P0001'; END IF;
 IF (g.board->p_cell->>'owner') IS NOT NULL THEN RAISE EXCEPTION 'cell already claimed' USING ERRCODE='P0001'; END IF;
 chosen_letter:=g.board->p_cell->>'letter';
 SELECT id INTO qid FROM horoof.questions WHERE subject_id=r.subject_id AND letter=chosen_letter AND review_status='approved' ORDER BY random() LIMIT 1;
 IF qid IS NULL THEN RAISE EXCEPTION 'no approved question for letter' USING ERRCODE='P0001'; END IF;
 UPDATE horoof.games SET active_cell=p_cell,question_id=qid,winner_user=NULL,answer_deadline=NULL,round_version=round_version+1,updated_at=clock_timestamp() WHERE room_id=p_room_id;
 RETURN qid;
END $$;
CREATE OR REPLACE FUNCTION horoof.claim_buzzer(p_room_id bigint,p_actor uuid) RETURNS TABLE(winner_user uuid,answer_deadline timestamptz,queued boolean) LANGUAGE plpgsql SECURITY INVOKER SET search_path = pg_catalog, horoof AS $$
DECLARE r horoof.rooms%ROWTYPE; g horoof.games%ROWTYPE; prior_id bigint; next_user uuid; inserted bigint;
BEGIN
 SELECT * INTO r FROM horoof.rooms WHERE id=p_room_id FOR UPDATE;
 IF NOT FOUND OR r.status <> 'playing' THEN RAISE EXCEPTION 'game unavailable' USING ERRCODE='P0001'; END IF;
 IF NOT EXISTS(SELECT 1 FROM horoof.room_players WHERE room_id=p_room_id AND user_id=p_actor) THEN RAISE EXCEPTION 'not a participant' USING ERRCODE='P0001'; END IF;
 SELECT * INTO g FROM horoof.games WHERE room_id=p_room_id FOR UPDATE;
 IF NOT FOUND OR g.active_cell IS NULL OR g.result IS NOT NULL THEN RAISE EXCEPTION 'no active question' USING ERRCODE='P0001'; END IF;
 INSERT INTO horoof.buzzes(room_id,round_version,user_id) VALUES(p_room_id,g.round_version,p_actor) ON CONFLICT DO NOTHING RETURNING id INTO inserted;
 IF inserted IS NULL THEN RAISE EXCEPTION 'already buzzed' USING ERRCODE='P0001'; END IF;
 IF g.winner_user IS NOT NULL AND g.answer_deadline <= clock_timestamp() THEN
   SELECT id INTO prior_id FROM horoof.buzzes WHERE room_id=p_room_id AND round_version=g.round_version AND user_id=g.winner_user;
   SELECT user_id INTO next_user FROM horoof.buzzes WHERE room_id=p_room_id AND round_version=g.round_version AND id>prior_id ORDER BY id LIMIT 1;
   g.winner_user:=next_user;
   g.answer_deadline:=CASE WHEN next_user IS NULL THEN NULL ELSE clock_timestamp()+interval '3 seconds' END;
 END IF;
 IF g.winner_user IS NULL THEN g.winner_user:=p_actor; g.answer_deadline:=clock_timestamp()+interval '3 seconds'; END IF;
 UPDATE horoof.games SET winner_user=g.winner_user,answer_deadline=g.answer_deadline,updated_at=clock_timestamp() WHERE room_id=p_room_id;
 RETURN QUERY SELECT g.winner_user,g.answer_deadline,(g.winner_user<>p_actor);
END $$;
REVOKE ALL ON FUNCTION horoof.select_cell(bigint,uuid,integer) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION horoof.claim_buzzer(bigint,uuid) FROM PUBLIC, anon, authenticated;
