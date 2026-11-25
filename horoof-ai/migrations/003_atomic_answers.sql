-- Trusted backend only: p_actor must come from validated server-side identity.
CREATE OR REPLACE FUNCTION horoof.normalize_answer(value text) RETURNS text LANGUAGE sql IMMUTABLE STRICT SET search_path=pg_catalog AS $$ SELECT regexp_replace(translate(regexp_replace(lower(trim(value)), '[ً-ٰٟـ]', '', 'g'), 'أإآةى', 'اااهي'), '\s+', ' ', 'g') $$;
CREATE OR REPLACE FUNCTION horoof.has_path(p_board jsonb,p_team text) RETURNS boolean LANGUAGE plpgsql IMMUTABLE STRICT SET search_path=pg_catalog AS $$
DECLARE queue integer[]:=ARRAY[]::integer[]; seen integer[]:=ARRAY[]::integer[]; i integer; j integer; r integer; c integer; dr integer; dc integer; nr integer; nc integer; pairs integer[][];
BEGIN
IF p_team NOT IN ('green','orange') OR jsonb_typeof(p_board)<>'array' OR jsonb_array_length(p_board)<>25 THEN RETURN false; END IF;
FOR i IN 0..24 LOOP r:=i/5; c:=i%5; IF p_board->i->>'owner'=p_team AND ((p_team='green' AND c=0) OR (p_team='orange' AND r=0)) THEN queue:=array_append(queue,i);seen:=array_append(seen,i); END IF; END LOOP;
WHILE coalesce(array_length(queue,1),0)>0 LOOP i:=queue[1];queue:=queue[2:]; r:=i/5;c:=i%5; IF (p_team='green' AND c=4) OR (p_team='orange' AND r=4) THEN RETURN true; END IF;
pairs:=ARRAY[[0,-1],[0,1],[-1,0],[1,0],[-1,CASE WHEN r%2=1 THEN -1 ELSE 1 END],[1,CASE WHEN r%2=1 THEN -1 ELSE 1 END]];
FOR j IN 1..6 LOOP dr:=pairs[j][1];dc:=pairs[j][2];nr:=r+dr;nc:=c+dc;IF nr>=0 AND nr<5 AND nc>=0 AND nc<5 THEN i:=nr*5+nc; IF NOT i=ANY(seen) AND p_board->i->>'owner'=p_team THEN seen:=array_append(seen,i);queue:=array_append(queue,i);END IF;END IF;END LOOP;
END LOOP;RETURN false;END $$;
CREATE OR REPLACE FUNCTION horoof.submit_answer(p_room_id bigint,p_actor uuid,p_answer text) RETURNS TABLE(correct boolean,game_won boolean,winning_team text) LANGUAGE plpgsql SECURITY INVOKER SET search_path=pg_catalog,horoof AS $$
DECLARE r horoof.rooms%ROWTYPE; g horoof.games%ROWTYPE; actor_team text; expected text; is_correct boolean; b jsonb; did_win boolean:=false; prior_id bigint; next_user uuid;
BEGIN
IF p_answer IS NULL OR char_length(trim(p_answer))<1 OR char_length(p_answer)>200 THEN RAISE EXCEPTION 'invalid answer' USING ERRCODE='P0001'; END IF;
SELECT * INTO r FROM horoof.rooms WHERE id=p_room_id FOR UPDATE; IF NOT FOUND OR r.status<>'playing' THEN RAISE EXCEPTION 'game unavailable' USING ERRCODE='P0001'; END IF;
SELECT team INTO actor_team FROM horoof.room_players WHERE room_id=p_room_id AND user_id=p_actor;IF NOT FOUND THEN RAISE EXCEPTION 'not a participant' USING ERRCODE='P0001'; END IF;
SELECT * INTO g FROM horoof.games WHERE room_id=p_room_id FOR UPDATE; IF NOT FOUND OR g.active_cell IS NULL OR g.winner_user IS DISTINCT FROM p_actor OR g.answer_deadline IS NULL OR g.answer_deadline<=clock_timestamp() THEN RAISE EXCEPTION 'no active answer turn' USING ERRCODE='P0001'; END IF;
SELECT answer INTO expected FROM horoof.questions WHERE id=g.question_id AND subject_id=r.subject_id AND review_status='approved';IF NOT FOUND THEN RAISE EXCEPTION 'question unavailable' USING ERRCODE='P0001'; END IF;
is_correct:=horoof.normalize_answer(p_answer)=horoof.normalize_answer(expected);
INSERT INTO horoof.answers(room_id,question_id,user_id,raw_answer,correct) VALUES(p_room_id,g.question_id,p_actor,p_answer,is_correct);
IF is_correct THEN
b:=jsonb_set(g.board,ARRAY[g.active_cell::text,'owner'],to_jsonb(actor_team),true);did_win:=horoof.has_path(b,actor_team);
UPDATE horoof.room_players SET score=score+10 WHERE room_id=p_room_id AND user_id=p_actor;
UPDATE horoof.games SET board=b,active_cell=NULL,question_id=NULL,winner_user=NULL,answer_deadline=NULL,turn_team=actor_team,result=CASE WHEN did_win THEN actor_team ELSE NULL END,updated_at=clock_timestamp() WHERE room_id=p_room_id;
IF did_win THEN UPDATE horoof.rooms SET status='finished' WHERE id=p_room_id;END IF;
ELSE
SELECT id INTO prior_id FROM horoof.buzzes WHERE room_id=p_room_id AND round_version=g.round_version AND user_id=p_actor;
SELECT user_id INTO next_user FROM horoof.buzzes WHERE room_id=p_room_id AND round_version=g.round_version AND id>prior_id ORDER BY id LIMIT 1;
UPDATE horoof.games SET winner_user=next_user,answer_deadline=CASE WHEN next_user IS NULL THEN NULL ELSE clock_timestamp()+interval '3 seconds' END,updated_at=clock_timestamp() WHERE room_id=p_room_id;
END IF;
RETURN QUERY SELECT is_correct,did_win,CASE WHEN did_win THEN actor_team ELSE NULL END;
END $$;
REVOKE ALL ON FUNCTION horoof.normalize_answer(text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION horoof.has_path(jsonb,text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION horoof.submit_answer(bigint,uuid,text) FROM PUBLIC, anon, authenticated;
