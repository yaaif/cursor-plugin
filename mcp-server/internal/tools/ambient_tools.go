package tools

import (
	"context"
	"fmt"
	"net/url"

	"github.com/modelcontextprotocol/go-sdk/mcp"
)

func (r *Registry) registerAmbient(server *mcp.Server) {
	addTool(server, "yaaif_agent_create", "Create a chat or workflow agent definition.",
		schemaObject(map[string]any{
			"name":         map[string]any{"type": "string"},
			"description":  map[string]any{"type": "string"},
			"goal_prompt":  map[string]any{"type": "string"},
			"agent_type":   map[string]any{"type": "string", "description": "chat (default) or workflow"},
			"skill_ids":    map[string]any{"type": "array", "items": map[string]any{"type": "string"}},
			"enabled":      map[string]any{"type": "boolean"},
		}, "name", "description", "goal_prompt"),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			name, err := requireString(args, "name")
			if err != nil {
				return nil, nil, err
			}
			description, err := requireString(args, "description")
			if err != nil {
				return nil, nil, err
			}
			goal, err := requireString(args, "goal_prompt")
			if err != nil {
				return nil, nil, err
			}
			skillIDs := stringSliceArg(args, "skill_ids")
			if skillIDs == nil {
				skillIDs = []string{}
			}
			body := map[string]any{
				"name":        name,
				"description": description,
				"goal_prompt": goal,
				"skill_ids":   skillIDs,
				"enabled":     boolArg(args, "enabled", true),
			}
			if agentType := strArg(args, "agent_type"); agentType != "" {
				body["agent_type"] = agentType
			}
			var out any
			if err := r.api.AgentJSON(ctx, "POST", "/api/agents", body, &out); err != nil {
				return nil, nil, err
			}
			return textResult(fmt.Sprintf("Created agent %s.", name), map[string]any{"agent": out})
		})

	addTool(server, "yaaif_ambient_agent_create", "Create an ambient agent config linked to a workflow agent.",
		schemaObject(map[string]any{
			"name":                   map[string]any{"type": "string"},
			"description":            map[string]any{"type": "string"},
			"agent_id":               map[string]any{"type": "string", "description": "Workflow agent UUID"},
			"enabled":                map[string]any{"type": "boolean"},
			"mode":                   map[string]any{"type": "string"},
			"workflow_async_enabled": map[string]any{"type": "boolean"},
			"requires_approval":      map[string]any{"type": "boolean"},
			"policy":                 map[string]any{"type": "object"},
		}, "name", "agent_id"),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			name, err := requireString(args, "name")
			if err != nil {
				return nil, nil, err
			}
			agentID, err := requireString(args, "agent_id")
			if err != nil {
				return nil, nil, err
			}
			body := map[string]any{
				"name":                   name,
				"description":            strArg(args, "description"),
				"agent_id":               agentID,
				"enabled":                boolArg(args, "enabled", true),
				"mode":                   firstNonEmpty(strArg(args, "mode"), "active"),
				"workflow_async_enabled": boolArg(args, "workflow_async_enabled", true),
				"requires_approval":      boolArg(args, "requires_approval", false),
			}
			if policy := mapArg(args, "policy"); policy != nil {
				body["policy"] = policy
			}
			var out any
			if err := r.api.AgentJSON(ctx, "POST", "/api/ambient/agents", body, &out); err != nil {
				return nil, nil, err
			}
			return textResult(fmt.Sprintf("Created ambient agent %s.", name), map[string]any{"ambient_agent": out})
		})

	addTool(server, "yaaif_ambient_workflow_create", "Install an ambient workflow graph under an ambient agent.",
		schemaObject(map[string]any{
			"ambient_agent_id":       map[string]any{"type": "string"},
			"name":                   map[string]any{"type": "string"},
			"description":            map[string]any{"type": "string"},
			"enabled":                map[string]any{"type": "boolean"},
			"workflow_async_enabled": map[string]any{"type": "boolean"},
			"requires_approval":      map[string]any{"type": "boolean"},
			"policy":                 map[string]any{"type": "object"},
			"workflow_graph":         map[string]any{"type": "object"},
			"trigger_rules":          map[string]any{"type": "array", "items": map[string]any{"type": "object"}},
		}, "ambient_agent_id", "name", "workflow_graph"),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			ambientAgentID, err := requireString(args, "ambient_agent_id")
			if err != nil {
				return nil, nil, err
			}
			name, err := requireString(args, "name")
			if err != nil {
				return nil, nil, err
			}
			graph := mapArg(args, "workflow_graph")
			if graph == nil {
				return nil, nil, fmt.Errorf("workflow_graph is required")
			}
			body := map[string]any{
				"name":                   name,
				"description":            strArg(args, "description"),
				"enabled":                boolArg(args, "enabled", true),
				"workflow_async_enabled": boolArg(args, "workflow_async_enabled", true),
				"requires_approval":      boolArg(args, "requires_approval", false),
				"workflow_graph":         graph,
			}
			if policy := mapArg(args, "policy"); policy != nil {
				body["policy"] = policy
			}
			if rules, ok := args["trigger_rules"].([]any); ok {
				body["trigger_rules"] = rules
			}
			var out any
			path := "/api/ambient/agents/" + url.PathEscape(ambientAgentID) + "/workflows"
			if err := r.api.AgentJSON(ctx, "POST", path, body, &out); err != nil {
				return nil, nil, err
			}
			return textResult(fmt.Sprintf("Created ambient workflow %s.", name), map[string]any{"workflow": out})
		})

	addTool(server, "yaaif_ambient_workflow_get", "Get an ambient workflow by id.",
		schemaObject(map[string]any{
			"workflow_id": map[string]any{"type": "string"},
		}, "workflow_id"),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			workflowID, err := requireString(args, "workflow_id")
			if err != nil {
				return nil, nil, err
			}
			var out any
			if err := r.api.AgentJSON(ctx, "GET", "/api/ambient/workflows/"+url.PathEscape(workflowID), nil, &out); err != nil {
				return nil, nil, err
			}
			return textResult("Fetched ambient workflow.", map[string]any{"workflow": out})
		})

	addTool(server, "yaaif_ambient_workflow_list", "List ambient workflows (optionally filter by ambient agent).",
		schemaObject(map[string]any{
			"ambient_agent_id": map[string]any{"type": "string"},
			"q":                map[string]any{"type": "string"},
		}),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			q := url.Values{}
			if id := strArg(args, "ambient_agent_id"); id != "" {
				q.Set("ambient_agent_id", id)
			}
			if s := strArg(args, "q"); s != "" {
				q.Set("q", s)
			}
			path := "/api/ambient/workflows"
			if enc := q.Encode(); enc != "" {
				path += "?" + enc
			}
			var out any
			if err := r.api.AgentJSON(ctx, "GET", path, nil, &out); err != nil {
				return nil, nil, err
			}
			return textResult("Listed ambient workflows.", map[string]any{"result": out})
		})

	addTool(server, "yaaif_ambient_workflow_update", "Update an ambient workflow graph / metadata.",
		schemaObject(map[string]any{
			"workflow_id":            map[string]any{"type": "string"},
			"name":                   map[string]any{"type": "string"},
			"description":            map[string]any{"type": "string"},
			"enabled":                map[string]any{"type": "boolean"},
			"workflow_async_enabled": map[string]any{"type": "boolean"},
			"requires_approval":      map[string]any{"type": "boolean"},
			"policy":                 map[string]any{"type": "object"},
			"workflow_graph":         map[string]any{"type": "object"},
			"trigger_rules":          map[string]any{"type": "array", "items": map[string]any{"type": "object"}},
			"expected_updated_at":    map[string]any{"type": "string"},
		}, "workflow_id"),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			workflowID, err := requireString(args, "workflow_id")
			if err != nil {
				return nil, nil, err
			}
			body := map[string]any{}
			for _, key := range []string{"name", "description", "expected_updated_at"} {
				if v := strArg(args, key); v != "" {
					body[key] = v
				}
			}
			for _, key := range []string{"enabled", "workflow_async_enabled", "requires_approval"} {
				if _, ok := args[key]; ok {
					body[key] = boolArg(args, key, false)
				}
			}
			if policy := mapArg(args, "policy"); policy != nil {
				body["policy"] = policy
			}
			if graph := mapArg(args, "workflow_graph"); graph != nil {
				body["workflow_graph"] = graph
			}
			if rules, ok := args["trigger_rules"].([]any); ok {
				body["trigger_rules"] = rules
			}
			var out any
			if err := r.api.AgentJSON(ctx, "PUT", "/api/ambient/workflows/"+url.PathEscape(workflowID), body, &out); err != nil {
				return nil, nil, err
			}
			return textResult("Updated ambient workflow.", map[string]any{"workflow": out})
		})

	addTool(server, "yaaif_ambient_test_trigger", "Fire a test signal against an ambient workflow.",
		schemaObject(map[string]any{
			"workflow_id": map[string]any{"type": "string"},
			"source":      map[string]any{"type": "string"},
			"event_type":  map[string]any{"type": "string"},
			"entity_type": map[string]any{"type": "string"},
			"entity_id":   map[string]any{"type": "string"},
			"payload":     map[string]any{"type": "object"},
		}, "workflow_id", "event_type", "entity_type", "entity_id"),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			workflowID, err := requireString(args, "workflow_id")
			if err != nil {
				return nil, nil, err
			}
			eventType, err := requireString(args, "event_type")
			if err != nil {
				return nil, nil, err
			}
			entityType, err := requireString(args, "entity_type")
			if err != nil {
				return nil, nil, err
			}
			entityID, err := requireString(args, "entity_id")
			if err != nil {
				return nil, nil, err
			}
			payload := mapArg(args, "payload")
			if payload == nil {
				payload = map[string]any{}
			}
			body := map[string]any{
				"source":      firstNonEmpty(strArg(args, "source"), "manual"),
				"event_type":  eventType,
				"entity_type": entityType,
				"entity_id":   entityID,
				"payload":     payload,
			}
			var out any
			path := "/api/ambient/workflows/" + url.PathEscape(workflowID) + "/test-trigger"
			if err := r.api.AgentJSON(ctx, "POST", path, body, &out); err != nil {
				return nil, nil, err
			}
			return textResult("Triggered ambient workflow test.", map[string]any{"result": out})
		})

	addTool(server, "yaaif_ambient_runs_list", "List ambient workflow runs.",
		schemaObject(map[string]any{
			"ambient_agent_id": map[string]any{"type": "string"},
			"workflow_id":      map[string]any{"type": "string"},
			"limit":            map[string]any{"type": "number"},
		}),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			q := url.Values{}
			if id := strArg(args, "ambient_agent_id"); id != "" {
				q.Set("ambient_agent_id", id)
			}
			if id := strArg(args, "workflow_id"); id != "" {
				q.Set("workflow_id", id)
			}
			if lim, ok := args["limit"].(float64); ok && lim > 0 {
				q.Set("limit", fmt.Sprintf("%d", int(lim)))
			}
			path := "/api/ambient/runs"
			if enc := q.Encode(); enc != "" {
				path += "?" + enc
			}
			var out any
			if err := r.api.AgentJSON(ctx, "GET", path, nil, &out); err != nil {
				return nil, nil, err
			}
			return textResult("Listed ambient runs.", map[string]any{"result": out})
		})

	addTool(server, "yaaif_ambient_run_get", "Get one ambient run by id.",
		schemaObject(map[string]any{
			"run_id": map[string]any{"type": "string"},
		}, "run_id"),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			runID, err := requireString(args, "run_id")
			if err != nil {
				return nil, nil, err
			}
			var out any
			if err := r.api.AgentJSON(ctx, "GET", "/api/ambient/runs/"+url.PathEscape(runID), nil, &out); err != nil {
				return nil, nil, err
			}
			return textResult("Fetched ambient run.", map[string]any{"run": out})
		})
}
