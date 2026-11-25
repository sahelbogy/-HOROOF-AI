# HOROOF AI — development MVP

A runnable first implementation of HOROOF, based on the approved 5 × 5 staggered 3D-style board. **This is not the complete platform or production-ready.** It uses a Node/Express server, SQLite for persistent data, and Socket.IO notifications.

## Run locally

Requirements: Node.js 20+ and npm. From this folder:

```sh
npm install
npm start
```

Open http://localhost:3000. For two-player testing, create separate accounts in separate browsers or private windows. The first player creates a party, shares the generated code, and the second joins. Both teams must have at least one player before the host starts. Press an available letter, buzz, then type the exact answer in Arabic within 25 seconds. If a player answers wrongly or times out, the next player in the buzz queue gets a turn. The host can reset a question if everyone runs out of attempts.

`OPENAI_API_KEY` enables real AI draft generation (optional); `OPENAI_MODEL` selects a compatible structured-output model. Set these as environment variables before starting. Do not put keys in frontend code. `PORT` changes the server port; `DB_PATH` changes the SQLite file (default `./horoof.sqlite`). The database and seed data are created at startup. The database file must reside on persistent storage. No demo credentials or fake live players are created; register your own accounts.

## Implemented
- Registration and login, bcrypt password hashing, SQLite-backed sessions, HTTP-only cookies plus a per-tab sessionStorage bearer-token fallback for embedded previews; logout. The token fallback is accessible to JavaScript and should be replaced or hardened for production (including a strict CSP and XSS review).
- Subject creation and manual questions, starter Arabic knowledge questions for up to 28 different letters in newly initialized databases. User-created subjects are visible only to their owner, though party participants can see the party subject.
- Random server-generated unique party codes, lobby joining/leaving, locally generated QR invitations (sign-in required), teams, ready indicator, host start and close.
- Random 5 × 5 Arabic honeycomb board, server-side selection, single server-authoritative buzzer winner, queue, 25-second deadline and reset.
- Server-side exact/normalized answer checking, capture and scoring, Hex path victory, leaderboard and profile statistics from finished matches.
- Optional browser-generated game sound effects, a mute control, subtle transitions and reduced-motion support.
- Optional browser speech recognition in supported browsers; the browser or its speech provider may process audio. Text fallback is always available; transcripts require confirmation.
- Private Knowledge Hub for owned collections: TXT and text-based PDF upload, extraction with PDF page numbers, SHA-256, processing status, chunks, simple exact-phrase search, retry and deletion. Limit 5 MB and 50 PDF pages. DOCX page numbers are not available; PPTX references are slide numbers. Complex Office features, vector indexing and hybrid search are not supported. Image-only PDF pages can use local OCR when enabled (up to 10 pages per PDF). OCR results require human verification. Processing runs in the web process, not a worker. A limited document-question workflow uses exact-phrase search, optional OpenAI generation, verbatim quote checks and required human review. It is not full hybrid RAG; an exact quote alone does not prove a question or answer is correct.
- An optional OpenAI-backed five-question draft generator: validates output, allows editing and saves only after approval. A subject needs 25 distinct letters to play; add remaining questions manually.
- Socket.IO update notifications with authenticated room subscription, responsive layout, basic transitions.

## Known gaps / limitations
- This is an MVP. Semantic grading, full hybrid/vector RAG, complete multilingual/RTL interface (an AR/FR/EN switch and partial translations are available, with English fallback), admin/moderation, password reset, detailed statistics, all other game modes, round series, full question lifecycle, and deployment integration are not yet implemented. AI generation needs an OpenAI key and a compatible model; only five-question drafts are generated. Browser speech recognition may be unavailable or inaccurate and is not a server-side transcription provider. The 25-second answer window may still be affected by network latency and transcription delays.
- Only starter questions are playable by default; a custom subject needs at least 25 distinct Arabic-letter questions to start a game. Questions and answers require review for educational quality.
- The app uses SQLite and a single Node process: suitable for local development and small single-instance demonstrations, not multi-instance production. Rate limits are in memory. No automated backups, advanced observability, hardened CSRF controls, email verification or session revocation UI. Review security, privacy, compliance, content, accessibility, and concurrency before deployment.
- The buzzer uses a transaction on a single SQLite instance. Browser reconnect retrieves current state. Network delay affects arrival order; the server time and arrival determine the winner.
- The 25-second limit includes network transit. Incorrect submissions can pass the turn only to other users who have already buzzed; late users may still buzz. Use host reset if no candidates remain.
- Only exact normalized answers are accepted; no claim is made of semantic understanding. The app does not store audio; browser speech services may transmit audio under their own policies.

## API
All endpoints are same-origin JSON. Protected endpoints require the `sid` cookie.

- `POST /api/register`, `/api/login`, `/api/logout`; `GET /api/me`
- `GET/POST /api/subjects`; `POST /api/subjects/:id/questions`
- `POST /api/parties` and `/api/parties/join`; `GET /api/parties/:code`
- `POST /api/parties/:code/{team,ready,start,select,buzz,answer,skip}`
- `POST /api/documents/:id/generate`, `GET /api/documents/:id/drafts`, `POST /api/drafts/:id/review` (requires explicit consent before passages are sent to OpenAI).
- `GET/POST /api/subjects/:id/documents`, `GET/DELETE /api/documents/:id`, `POST /api/documents/:id/reprocess`, `GET /api/subjects/:id/search?q=...`
- `GET /api/leaderboard`, `/api/statistics/me`; `POST /api/profile`
- `POST /api/ai/generate` (requires an OpenAI key) and `/api/ai/save`
- Socket.IO `party:subscribe` and `party:updated`: clients must refetch authorized state after notification.

## Tests

```sh
npm test
```

Tests use an in-memory isolated database and cover registration, login rejection, protected endpoints, party flow, concurrent buzzer requests, answer secrecy, scoring, hex path victory, and seed coverage. They do not constitute a production security audit or comprehensive browser/device test.

See `SPEC_REVIEW.md` for the gap analysis against the submitted requirements. The document upload and extraction code is a development implementation and requires hardened file parsing and security review before deployment.

## Local OCR and Docker

Set `OCR_ENABLED=1` and install `tesseract-ocr`, `tesseract-ocr-ara`, `tesseract-ocr-fra`, and `poppler-utils` to recognize image-only PDF pages locally. English is included in the usual Tesseract package. `OCR_LANGUAGES` defaults to `ara+fra+eng`. At most 10 image-only pages are processed; failed/unavailable OCR is reported in document status. OCR is CPU-intensive, can be inaccurate and is not isolated from untrusted documents in a hardened worker.

For a single-node local demo, `docker compose up --build` starts the SQLite app and OCR with a persistent Docker volume. This compose configuration is a development setup, not a production or Vercel deployment. It has not been tested in this environment because Docker is unavailable.

### Browser smoke test
After installing dependencies and Playwright's Chromium (`npx playwright install --with-deps chromium`), run `npm run test:browser`. The test starts a disposable local SQLite server and checks two-player registration, room creation/join, the 25-cell board, buzzing and capture, Arabic RTL on a mobile-size viewport, and sign-in followed by room creation with cookies cleared. It does not test live Supabase authentication, a deployed Vercel app, every mobile device, or real-time race conditions.

The separate serverless prototype now includes a password recovery interface, but recovery email delivery and redirect URLs have not been verified against live Supabase. The local SQLite preview does not provide password recovery.

When creating a room, choose the **question language** independently of the interface language. A playable collection needs questions for 25 distinct Arabic letters in that language; answers still begin with the selected Arabic letter. The supplied starter collection is Arabic only. Existing SQLite questions from before language tracking default to Arabic and may need review.

The local preview now also supports a French A–Z board. Choose **Culture générale française**, **French** question language, and **French letters (A–Z)** to play; these are preselected for new rooms. The 5×5 game chooses 25 of the 26 letters at random. Arabic board letters remain available. AI question generation still requires Arabic-letter answers; French-letter questions can be added manually.
