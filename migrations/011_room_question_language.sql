ALTER TABLE horoof.rooms ADD COLUMN question_language text NOT NULL DEFAULT 'ar' CHECK(question_language IN ('ar','fr','en'));
DO $migration$
DECLARE definition text; updated text; needle text := 'subject_id=r.subject_id AND letter=chosen_letter AND review_status='; replacement text := 'subject_id=r.subject_id AND language=r.question_language AND letter=chosen_letter AND review_status=';
BEGIN
 definition:=pg_get_functiondef('horoof.select_cell(bigint,uuid,integer)'::regprocedure);
 IF strpos(definition,needle)=0 OR (length(definition)-length(replace(definition,needle,'')))/length(needle)<>1 THEN RAISE EXCEPTION 'Unexpected question selection function'; END IF;
 updated:=replace(definition,needle,replacement);
 EXECUTE updated;
END
$migration$;
CREATE INDEX questions_subject_language_letter_approved ON horoof.questions(subject_id,language,letter) WHERE review_status='approved';
