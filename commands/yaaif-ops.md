---
name: yaaif-ops
description: Read-only ops support — correlate and analyze session/ambient/desktop failures
---

Use the `yaaif-ops-support` skill. Authenticate if needed, collect a session_id /
ambient_run_id / desktop_run_id / request_id, call `yaaif_ops_analyze`, and report
linked IDs + failures + next steps. Do not call any mutating ambient/desktop tools.
