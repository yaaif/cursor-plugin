package tools

import (
	"context"
	"fmt"
	"net/url"
	"strings"

	"github.com/modelcontextprotocol/go-sdk/mcp"
)

func (r *Registry) registerSkills(server *mcp.Server) {
	addTool(server, "yaaif_skill_list", "List skills in the tenant catalog.",
		schemaObject(map[string]any{
			"q":     map[string]any{"type": "string"},
			"limit": map[string]any{"type": "number"},
		}),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			q := url.Values{}
			if s := strArg(args, "q"); s != "" {
				q.Set("q", s)
			}
			if lim, ok := args["limit"].(float64); ok && lim > 0 {
				q.Set("limit", fmt.Sprintf("%d", int(lim)))
			}
			path := "/api/skills"
			if encoded := q.Encode(); encoded != "" {
				path += "?" + encoded
			}
			var out any
			if err := r.api.AgentJSON(ctx, "GET", path, nil, &out); err != nil {
				return nil, nil, err
			}
			return textResult("Listed skills.", map[string]any{"result": out})
		})

	addTool(server, "yaaif_skill_get", "Get one skill by id.",
		schemaObject(map[string]any{
			"skill_id": map[string]any{"type": "string"},
		}, "skill_id"),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			skillID, err := requireString(args, "skill_id")
			if err != nil {
				return nil, nil, err
			}
			var out any
			if err := r.api.AgentJSON(ctx, "GET", "/api/skills/"+url.PathEscape(skillID), nil, &out); err != nil {
				return nil, nil, err
			}
			return textResult("Fetched skill.", map[string]any{"skill": out})
		})

	addTool(server, "yaaif_skill_create", "Create a skill pack in YAAIF (writes SKILL.md + skill_configs).",
		schemaObject(map[string]any{
			"id":                   map[string]any{"type": "string", "description": "Skill id / relative path, e.g. domain/my-skill"},
			"name":                 map[string]any{"type": "string"},
			"description":          map[string]any{"type": "string"},
			"instruction":          map[string]any{"type": "string", "description": "SKILL.md body markdown"},
			"tools":                map[string]any{"type": "array", "items": map[string]any{"type": "string"}},
			"allowed_tools":        map[string]any{"type": "array", "items": map[string]any{"type": "string"}},
			"classification":       map[string]any{"type": "string"},
			"enabled":              map[string]any{"type": "boolean"},
			"updated_by":           map[string]any{"type": "string"},
			"assigned_user_emails": map[string]any{"type": "array", "items": map[string]any{"type": "string"}},
			"include_references":   map[string]any{"type": "boolean"},
			"include_examples":     map[string]any{"type": "boolean"},
		}, "id", "description", "instruction"),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			id, err := requireString(args, "id")
			if err != nil {
				return nil, nil, err
			}
			description, err := requireString(args, "description")
			if err != nil {
				return nil, nil, err
			}
			instruction, err := requireString(args, "instruction")
			if err != nil {
				return nil, nil, err
			}
			name := strArg(args, "name")
			if name == "" {
				parts := strings.Split(id, "/")
				name = parts[len(parts)-1]
			}
			body := map[string]any{
				"id":                   id,
				"name":                 name,
				"description":          description,
				"instruction":          instruction,
				"tools":                stringSliceArg(args, "tools"),
				"allowed_tools":        stringSliceArg(args, "allowed_tools"),
				"classification":       firstNonEmpty(strArg(args, "classification"), "general"),
				"enabled":              boolArg(args, "enabled", true),
				"updated_by":           firstNonEmpty(strArg(args, "updated_by"), "yaaif-cursor"),
				"assigned_user_emails": stringSliceArg(args, "assigned_user_emails"),
				"scaffold": map[string]any{
					"include_references": boolArg(args, "include_references", true),
					"include_examples":   boolArg(args, "include_examples", true),
				},
			}
			if body["tools"] == nil {
				body["tools"] = []string{}
			}
			if body["allowed_tools"] == nil {
				body["allowed_tools"] = body["tools"]
			}
			if body["assigned_user_emails"] == nil {
				body["assigned_user_emails"] = []string{}
			}
			var out any
			if err := r.api.AgentJSON(ctx, "POST", "/api/skills", body, &out); err != nil {
				return nil, nil, err
			}
			return textResult(fmt.Sprintf("Created skill %s.", id), map[string]any{"skill": out})
		})

	addTool(server, "yaaif_skill_write_file", "Create or update a skill pack file under the tenant skills tree.",
		schemaObject(map[string]any{
			"path":    map[string]any{"type": "string", "description": "Relative path e.g. domain/my-skill/SKILL.md"},
			"content": map[string]any{"type": "string"},
			"method":  map[string]any{"type": "string", "enum": []string{"POST", "PUT"}, "description": "POST create, PUT update (default PUT)"},
		}, "path", "content"),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			path, err := requireString(args, "path")
			if err != nil {
				return nil, nil, err
			}
			content, err := requireString(args, "content")
			if err != nil {
				return nil, nil, err
			}
			method := strings.ToUpper(firstNonEmpty(strArg(args, "method"), "PUT"))
			var out any
			if err := r.api.AgentJSON(ctx, method, "/api/skill-files/content", map[string]any{
				"path":    path,
				"content": content,
			}, &out); err != nil {
				return nil, nil, err
			}
			return textResult(fmt.Sprintf("Wrote skill file %s.", path), map[string]any{"result": out})
		})

	addTool(server, "yaaif_skill_enable", "Enable or disable a skill in skill_configs.",
		schemaObject(map[string]any{
			"skill_id":   map[string]any{"type": "string"},
			"enabled":    map[string]any{"type": "boolean"},
			"updated_by": map[string]any{"type": "string"},
		}, "skill_id", "enabled"),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			skillID, err := requireString(args, "skill_id")
			if err != nil {
				return nil, nil, err
			}
			enabled, ok := args["enabled"].(bool)
			if !ok {
				return nil, nil, fmt.Errorf("enabled is required")
			}
			var out any
			if err := r.api.AgentJSON(ctx, "POST", "/api/skills/enablement", map[string]any{
				"skill_id":   skillID,
				"enabled":    enabled,
				"updated_by": firstNonEmpty(strArg(args, "updated_by"), "yaaif-cursor"),
			}, &out); err != nil {
				return nil, nil, err
			}
			return textResult(fmt.Sprintf("Skill %s enabled=%v.", skillID, enabled), map[string]any{"skill": out})
		})

	addTool(server, "yaaif_skill_map_agents", "Replace agent→skill mappings (bulk).",
		schemaObject(map[string]any{
			"assignments": map[string]any{
				"type": "array",
				"items": map[string]any{
					"type": "object",
					"properties": map[string]any{
						"agent_id":  map[string]any{"type": "string"},
						"skill_ids": map[string]any{"type": "array", "items": map[string]any{"type": "string"}},
					},
					"required": []string{"agent_id", "skill_ids"},
				},
			},
		}, "assignments"),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			raw, ok := args["assignments"].([]any)
			if !ok || len(raw) == 0 {
				return nil, nil, fmt.Errorf("assignments is required")
			}
			assignments := make([]map[string]any, 0, len(raw))
			for _, item := range raw {
				m, ok := item.(map[string]any)
				if !ok {
					continue
				}
				agentID := strings.TrimSpace(fmt.Sprint(m["agent_id"]))
				skillIDs := stringSliceArg(m, "skill_ids")
				if agentID == "" {
					continue
				}
				assignments = append(assignments, map[string]any{
					"agent_id":  agentID,
					"skill_ids": skillIDs,
				})
			}
			if len(assignments) == 0 {
				return nil, nil, fmt.Errorf("no valid assignments")
			}
			var out any
			if err := r.api.AgentJSON(ctx, "POST", "/api/agents/skills/bulk", map[string]any{
				"assignments": assignments,
			}, &out); err != nil {
				return nil, nil, err
			}
			return textResult("Updated agent skill mappings.", map[string]any{"result": out})
		})

	addTool(server, "yaaif_skill_validate", "Validate one skill or the catalog.",
		schemaObject(map[string]any{
			"skill_id": map[string]any{"type": "string"},
			"strict":   map[string]any{"type": "boolean"},
		}),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			body := map[string]any{
				"strict": boolArg(args, "strict", false),
			}
			if skillID := strArg(args, "skill_id"); skillID != "" {
				body["skill_id"] = skillID
			}
			var out any
			if err := r.api.AgentJSON(ctx, "POST", "/api/skills/validate", body, &out); err != nil {
				return nil, nil, err
			}
			return textResult("Validated skills.", map[string]any{"result": out})
		})

	addTool(server, "yaaif_skill_refresh", "Re-discover skill files into the catalog.",
		schemaObject(map[string]any{}),
		func(ctx context.Context, _ map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			var out any
			if err := r.api.AgentJSON(ctx, "POST", "/api/skills/refresh", map[string]any{}, &out); err != nil {
				return nil, nil, err
			}
			return textResult("Refreshed skill catalog.", map[string]any{"result": out})
		})

	addTool(server, "yaaif_skill_runtime_reload", "Reload in-memory skill runtime for agents.",
		schemaObject(map[string]any{}),
		func(ctx context.Context, _ map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			var out any
			if err := r.api.AgentJSON(ctx, "POST", "/api/skills/runtime-reload", map[string]any{}, &out); err != nil {
				return nil, nil, err
			}
			return textResult("Reloaded skill runtime.", map[string]any{"result": out})
		})
}
