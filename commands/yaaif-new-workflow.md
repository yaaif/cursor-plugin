---
name: yaaif-new-workflow
description: Create an ambient workflow on YAA\F and test-trigger it
---

Use the `yaaif-create-ambient` skill. Ensure auth and domain MCP tools first. Create workflow agent → ambient agent → **step-only** workflow graph (ACTION / MESSAGE / BRANCH / WAIT / HUMAN / TERMINAL — not watcher / evaluator / guardian / orchestrator / recorder) → test-trigger.
