# File artifacts (Cursor)

YAA\F ingested files have dual identity:

| Reference | Scope | Version |
|-----------|-------|---------|
| Durable `file_id` (UUID) | Exact row | N/A (row is already a version) |
| Artifact name (`report.pdf`) | Current session | Auto-incrementing `artifact_version` |
| `user:profile.json` | Cross-session user library | Auto-incrementing (requires non-empty `user_id`) |

## Prefer local tools (skill frontmatter)

Call `yaaif_dev_session_ensure` first, then:

| Goal | Local tool / alias |
|------|--------------------|
| List session uploads | `files_list` / `yaaif_files_list` |
| Search by name/preview | `files_search` / `yaaif_files_search` |
| List or load by human-readable name | `load_artifacts` / `yaaif_load_artifacts` |
| Page extracted text (`offset` / `max_chars`) | `file_load_context` / `yaaif_file_load_context` |
| Mint short-lived URL for external MCP | `file_share_link` / `yaaif_file_share_link` |
| Create a downloadable file | `generate_file` / `yaaif_generate_file` |

Frontmatter example:

```yaml
tools:
  - files_list
  - load_artifacts
  - file_load_context
```

`file_load_context` and `load_artifacts` accept either a durable `file_id` or an artifact filename, plus optional `version` (omit/0 = latest).

## REST helpers (ops / version history)

| Tool | Backend |
|------|---------|
| `yaaif_session_files_list` | `GET /api/files` — set `latest_only=true` to one row per artifact name |
| `yaaif_file_artifact_versions` | `GET /api/files/artifacts/versions?artifact_name=` |
| `yaaif_file_get_extracted` | `GET /api/files/extracted` (`file_id` or name + optional `version`) |
| `yaaif_file_artifact_delete` | `DELETE /api/files/artifacts` (`confirm=true`) |

## Doctor checks

`yaaif_doctor` validates:

- `local_tools_files` — files family includes `files_list`, `file_load_context`, `load_artifacts`
- `local_tools_files_smoke` — ensure/create a Cursor dev session, then call `files_list` + empty `load_artifacts`
- `file_registry` / `file_registry_storage` — `GET /api/file-attachments/registry-lifecycle`
- `file_artifacts_api` — `GET /api/files/artifacts/versions` mounted (expects 400 without `artifact_name`)

## Authoring tip

When the user (or skill) refers to a document by filename and may overwrite it across turns, prefer `load_artifacts` with the artifact name and `yaaif_file_artifact_versions` if you need a historical revision.
