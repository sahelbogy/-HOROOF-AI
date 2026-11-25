-- Private database storage for the serverless document prototype.
-- Size capped to 4 MiB to fit within a serverless request envelope.
ALTER TABLE horoof.documents ADD COLUMN original bytea;
ALTER TABLE horoof.documents ADD CONSTRAINT document_file_size CHECK (size >= 0 AND size <= 4194304);
CREATE INDEX document_chunks_search_idx ON horoof.document_chunks(document_id,chunk_order);
