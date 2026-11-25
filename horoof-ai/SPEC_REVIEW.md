# Review against “Cahier des charges Horoof Arena Multilingue”

Reviewed the 11-page provided specification. Status refers to the local development MVP, not a production deployment.

## Available or partially available

- Accounts and sessions; server-authoritative rooms, two teams, lobby and code joining.
- The 25-cell Hex board, server-side scoring, buzzer and path-win detection. Existing automated tests cover winning paths and a two-player flow; reconnect requests a server snapshot after a socket reconnect. Room event sequence numbers and comprehensive race/idempotency tests are missing.
- History and basic profile statistics for completed games.
- QR invitation links, lobby leave and host close; QR joining still requires an account.
- An AR/FR/EN language selector with RTL for Arabic and partial UI translations. Untranslated strings fall back to English; game content and language-specific letter rules are not yet configurable.
- Basic optional speech recognition, optional sound and reduced-motion-aware UI.
- Newly added private Knowledge Hub for collection owners, with TXT, text-based PDF, DOCX and PPTX (up to 5 MB; PDF up to 50 pages and PPTX up to 200 slides), SHA-256 checksum, queued/extracting/ready/failed status, source passages and PDF page numbers, simple exact-phrase search, retry and deletion. Original files and chunks are stored in the local SQLite database. Text is not sent to AI. Optional local OCR is available when Tesseract, Poppler and language packs are installed; it handles up to 10 image-only pages. There is no separate asynchronous worker service. DOCX page references are unavailable and complex Office layouts may lose content; PPTX references use slide numbers.
- A limited sourced-question workflow retrieves exact phrase matches from an owned document, requires explicit consent before sending passages to OpenAI, checks that the returned quote appears verbatim, and requires human review before adding a question. No semantic evidence verification is provided; citations do not establish correctness. Tested with a mock AI provider, not live credentials.
- Standalone AI draft generation if an OpenAI API key is configured. This is **general question generation, not document-based RAG**. Outputs need human review; it is not sourced from imported documents. A board needs 25 distinct-letter questions.

## Missing or incomplete MVP items

1. Full trilingual interface, RTL, independently configurable question language, locale files, language-specific letter and answer rules (F05, F14, AC12–14).
2. Full room lifecycle, live-game leaving, detailed host controls, and robust reconnection / event sequencing (F02–F04, AC15). QR invitation, lobby leave and host close are implemented.
3. Production-grade OCR quality assessment and secure extraction isolation, comprehensive page-specific extraction testing, asynchronous worker, document versioning and deeper MIME/malware analysis (F09–F10, AC07–08). TXT, text-based PDF, DOCX and PPTX are supported with basic signature and archive-structure checks; image-only PDF pages use OCR when configured and otherwise fail explicitly. DOCX page numbering is not available.
4. Embeddings, vector + lexical retrieval, fusion, semantic evidence verification, and full granular question publishing (F11–F13, AC09–11). The limited document workflow uses only exact-phrase retrieval, checks a verbatim quote, and lets the owner approve or reject a draft. Do not describe it as full hybrid RAG.
5. Comprehensive roles and admin permissions, password reset, detailed audit log, hardening, moderation and verified privacy controls.
6. PostgreSQL-backed application integration, tested Docker Compose, Vercel-compatible backend, production deployment, automated browser/RTL/device tests and operational monitoring.

The specification leaves letter rules, timeouts and other game decisions open. Confirm these before expanding game logic. Knowledge Hub uploads and extraction are local. Document question generation sends selected matching passages to OpenAI only after explicit consent. General-topic generation sends the topic only when configured and requested.

## Serverless prototype updates
The separate serverless prototype now has a bounded opt-in lexical/embedding hybrid retrieval mode and a mock-tested password recovery flow. It is not a scalable vector index, and neither live AI nor recovery email delivery has been verified. Migration 009 adds a starter collection, which still requires independent review. The local SQLite preview does not include these serverless-only features.
