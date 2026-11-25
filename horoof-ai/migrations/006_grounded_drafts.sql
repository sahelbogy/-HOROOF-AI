CREATE TABLE horoof.grounded_drafts (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,subject_id bigint NOT NULL REFERENCES horoof.subjects(id) ON DELETE CASCADE,document_id bigint NOT NULL REFERENCES horoof.documents(id) ON DELETE CASCADE,chunk_id bigint NOT NULL REFERENCES horoof.document_chunks(id) ON DELETE CASCADE,letter text NOT NULL,question text NOT NULL,answer text NOT NULL,explanation text NOT NULL DEFAULT '',source_quote text NOT NULL,language text NOT NULL CHECK(language IN ('Arabic','English','French')),status text NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','approved','rejected')),model text NOT NULL,created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE horoof.question_sources (question_id bigint PRIMARY KEY REFERENCES horoof.questions(id) ON DELETE CASCADE,document_id bigint REFERENCES horoof.documents(id) ON DELETE SET NULL,filename text NOT NULL,page integer,checksum text NOT NULL,source_quote text NOT NULL,model text NOT NULL);
CREATE TABLE horoof.ai_usage (user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,minute timestamptz NOT NULL,requests integer NOT NULL CHECK(requests>0),PRIMARY KEY(user_id,minute));
CREATE INDEX grounded_drafts_document_owner ON horoof.grounded_drafts(document_id,owner_id);
ALTER TABLE horoof.grounded_drafts ENABLE ROW LEVEL SECURITY;
ALTER TABLE horoof.question_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE horoof.ai_usage ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON horoof.grounded_drafts,horoof.question_sources,horoof.ai_usage FROM PUBLIC,anon,authenticated;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA horoof FROM PUBLIC,anon,authenticated;
