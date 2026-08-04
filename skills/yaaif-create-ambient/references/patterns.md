# Ambient workflow patterns

| Pattern | When | Shape |
|---------|------|--------|
| Linear | Single automated path | One graph |
| Linear + approval | HITL gate | Graph with `approval` nodes + published `approval_strategy_id` |
| Branching | Multi-route | `switch` / `if` |
| Recon / resolve | Batch detect then clearance | Often two graphs |
| Chat-triggered | Chat starts graph | Graph + chat skill with trigger tools |

Minimal linear skeleton:

```json
{
  "nodes": [
    { "id": "watcher", "type": "watcher", "config": {} },
    { "id": "evaluator", "type": "evaluator", "config": {} },
    { "id": "guardian", "type": "guardian", "config": {} },
    { "id": "orchestrator", "type": "orchestrator", "config": {} },
    { "id": "recorder", "type": "recorder", "config": {} }
  ],
  "edges": [
    { "from": "watcher", "to": "evaluator" },
    { "from": "evaluator", "to": "guardian" },
    { "from": "guardian", "to": "orchestrator" },
    { "from": "orchestrator", "to": "recorder" }
  ]
}
```

Tool names inside step configs must match the MCP catalog exactly.
