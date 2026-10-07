# Verification record

## Current handoff — 7 October 2026

- Read-only Supabase check repeated: public Auth settings HTTP 200; email signup enabled; email confirmation required.
- Remote database check: `rooms` is not deployed/exposed (`PGRST205`).
- Remote Edge endpoint: `design-api` is not deployed (HTTP 404).
- Public config matches the supplied project; recovery from the tracked public config passed. The configuration helper rejects extra secret fields and secret/service-role key formats.
- Python helper syntax, shell entry-point syntax and GitHub workflow YAML/shell syntax checks passed. Action SHA pins and the Flutter tag were resolved against their official repositories; SDK/NDK constants were checked against the pinned Flutter source.
- Shopping secret example corrected to `SERPAPI_KEY`, matching the function.
- Language-button listener corrected; a label assertion was added to the existing widget test. **The updated Flutter test and analysis have not been rerun** because a functioning Flutter SDK is unavailable in this workspace.
- Gradle memory limits reduced for common CI runner sizes. Native compilation remains unverified.
- **APK: not built.** SDK bootstrap/build attempts did not complete successfully; no installable binary is included.
- **GitHub Actions: not executed.** A manual build workflow is included for execution in the owner's repository. Source validation does not establish that the build passes.
- **Backend: not deployed.** No remote migration, function deployment or secret change was performed.
- **Live AI and shopping: not tested.** No Gemini/SerpAPI secret or funded provider account was supplied.

## Previous source checkpoint — 6 October 2026

These results apply to the previous checkpoint, before the language-button/build-package changes above:

- Deno backend type check: passed.
- Deno validation tests: 5 passed.
- Isolated SQL/RLS harness: 13 checks passed (ownership, storage, idempotency, quotas, privileged functions and deletion locks).
- Flutter analysis: no issues found.
- Flutter tests: 4 passed, including narrow-screen Urdu sign-in/privacy layout.

The Deno and SQL implementation is unchanged in this handoff. The SQL harness uses mocked auth/storage schemas and does not replace a hosted Supabase test.

## Remaining acceptance checks

1. Run the included workflow or local build script; retain a successful analysis/test/build log and install the resulting APK.
2. Deploy migration/function with project-owner access, set `GEMINI_API_KEY` server-side, and configure the auth redirect.
3. On Android, verify signup/confirmation, password recovery, upload, a real redesign, object pins and external shopping links.
4. With two real accounts, verify private-image and room isolation; then test room and account deletion.

No fake generated room, product availability or prices are presented as live data. Source checks do not establish a working deployed provider workflow.
