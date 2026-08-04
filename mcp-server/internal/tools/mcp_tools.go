package tools

import (
	"context"
	"fmt"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/modelcontextprotocol/go-sdk/mcp"
)

var kebabNameRE = regexp.MustCompile(`^[a-z0-9]+(?:-[a-z0-9]+)*$`)

func (r *Registry) registerMCP(server *mcp.Server) {
	addTool(server, "yaaif_mcp_scaffold", "Scaffold a new MCP server from official YAAIF templates into the workspace.",
		schemaObject(map[string]any{
			"name":          map[string]any{"type": "string", "description": "Kebab service name without -mcp-service suffix, e.g. freight-audit"},
			"language":      map[string]any{"type": "string", "enum": []string{"go", "python"}, "description": "Template language (default go)"},
			"target_dir":    map[string]any{"type": "string", "description": "Parent directory (default ./mcp-servers)"},
			"workspace_root": map[string]any{"type": "string", "description": "Workspace root for relative target_dir (default cwd)"},
		}, "name"),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			name, err := requireString(args, "name")
			if err != nil {
				return nil, nil, err
			}
			name = strings.TrimSuffix(name, "-mcp-service")
			if !kebabNameRE.MatchString(name) {
				return nil, nil, fmt.Errorf("name must be kebab-case: %q", name)
			}
			lang := firstNonEmpty(strArg(args, "language"), "go")
			workspace := firstNonEmpty(strArg(args, "workspace_root"), mustGetwd())
			parent := firstNonEmpty(strArg(args, "target_dir"), "mcp-servers")
			if !filepath.IsAbs(parent) {
				parent = filepath.Join(workspace, parent)
			}
			serviceDirName := name + "-mcp-service"
			dest := filepath.Join(parent, serviceDirName)
			if _, err := os.Stat(dest); err == nil {
				return nil, nil, fmt.Errorf("destination already exists: %s", dest)
			}
			if err := os.MkdirAll(parent, 0o755); err != nil {
				return nil, nil, err
			}

			repo := "https://github.com/yaaif/mcp-server-templates-go.git"
			if lang == "python" {
				repo = "https://github.com/yaaif/mcp-server-templates-py.git"
			}
			tmp, err := os.MkdirTemp("", "yaaif-mcp-scaffold-*")
			if err != nil {
				return nil, nil, err
			}
			defer os.RemoveAll(tmp)

			clone := exec.CommandContext(ctx, "git", "clone", "--depth", "1", repo, tmp)
			clone.Stdout = os.Stderr
			clone.Stderr = os.Stderr
			if err := clone.Run(); err != nil {
				return nil, nil, fmt.Errorf("git clone template: %w", err)
			}

			// Copy template tree into dest (exclude .git).
			if err := copyDir(tmp, dest); err != nil {
				return nil, nil, err
			}
			_ = os.RemoveAll(filepath.Join(dest, ".git"))

			renameScript := filepath.Join(dest, "scripts", "rename-service.sh")
			if _, err := os.Stat(renameScript); err == nil {
				cmd := exec.CommandContext(ctx, "bash", renameScript, name)
				cmd.Dir = dest
				cmd.Stdout = os.Stderr
				cmd.Stderr = os.Stderr
				_ = cmd.Run() // best-effort; templates may vary
			}

			return textResult(fmt.Sprintf("Scaffolded MCP service at %s.", dest), map[string]any{
				"path":     dest,
				"name":     serviceDirName,
				"language": lang,
				"template": repo,
				"next_steps": []string{
					"Implement tools from contracts",
					"Build and push container image",
					"Call yaaif_mcp_deployment_create + deploy + register",
				},
			})
		})

	addTool(server, "yaaif_mcp_deployment_create", "Create an MCP deployment record (api-server → deployment-service).",
		schemaObject(map[string]any{
			"name":                   map[string]any{"type": "string"},
			"image":                  map[string]any{"type": "string"},
			"deployment_method":      map[string]any{"type": "string", "enum": []string{"docker_compose", "kubernetes_gitops"}},
			"container_port":         map[string]any{"type": "number"},
			"mcp_path":               map[string]any{"type": "string"},
			"endpoint_mode":          map[string]any{"type": "string"},
			"endpoint_host":          map[string]any{"type": "string"},
			"transport_type":         map[string]any{"type": "string"},
			"env":                    map[string]any{"type": "object"},
			"auto_register":          map[string]any{"type": "boolean"},
			"auto_import_tools":      map[string]any{"type": "boolean"},
			"registry_credential_id": map[string]any{"type": "string"},
		}, "name", "image"),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			name, err := requireString(args, "name")
			if err != nil {
				return nil, nil, err
			}
			image, err := requireString(args, "image")
			if err != nil {
				return nil, nil, err
			}
			port := 8080
			if p, ok := args["container_port"].(float64); ok && p > 0 {
				port = int(p)
			}
			env := map[string]string{}
			if raw := mapArg(args, "env"); raw != nil {
				for k, v := range raw {
					env[k] = fmt.Sprint(v)
				}
			}
			body := map[string]any{
				"name":                   name,
				"image":                  image,
				"deployment_method":      firstNonEmpty(strArg(args, "deployment_method"), "docker_compose"),
				"container_port":         port,
				"mcp_path":               firstNonEmpty(strArg(args, "mcp_path"), "/mcp"),
				"endpoint_mode":          firstNonEmpty(strArg(args, "endpoint_mode"), "docker_name"),
				"transport_type":         firstNonEmpty(strArg(args, "transport_type"), "HTTP"),
				"env":                    env,
				"secret_env":             []any{},
				"client_secret_headers":  []any{},
				"auto_register":          boolArg(args, "auto_register", true),
				"auto_import_tools":      boolArg(args, "auto_import_tools", true),
			}
			if host := strArg(args, "endpoint_host"); host != "" {
				body["endpoint_host"] = host
			}
			if cred := strArg(args, "registry_credential_id"); cred != "" {
				body["registry_credential_id"] = cred
			}
			var out any
			if err := r.api.APIJSON(ctx, "POST", "/api/mcp-deployments", body, &out); err != nil {
				return nil, nil, err
			}
			return textResult(fmt.Sprintf("Created MCP deployment %s.", name), map[string]any{"deployment": out})
		})

	addTool(server, "yaaif_mcp_deployment_deploy", "Deploy an MCP deployment by id.",
		schemaObject(map[string]any{
			"deployment_id": map[string]any{"type": "string"},
		}, "deployment_id"),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			id, err := requireString(args, "deployment_id")
			if err != nil {
				return nil, nil, err
			}
			var out any
			if err := r.api.APIJSON(ctx, "POST", "/api/mcp-deployments/"+url.PathEscape(id)+"/deploy", map[string]any{}, &out); err != nil {
				return nil, nil, err
			}
			return textResult("Deploy started/updated.", map[string]any{"deployment": out})
		})

	addTool(server, "yaaif_mcp_deployment_register", "Register a deployed MCP server into the agent-service tool catalog.",
		schemaObject(map[string]any{
			"deployment_id": map[string]any{"type": "string"},
		}, "deployment_id"),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			id, err := requireString(args, "deployment_id")
			if err != nil {
				return nil, nil, err
			}
			var out any
			if err := r.api.APIJSON(ctx, "POST", "/api/mcp-deployments/"+url.PathEscape(id)+"/register", map[string]any{}, &out); err != nil {
				return nil, nil, err
			}
			return textResult("Registered MCP deployment into catalog.", map[string]any{"deployment": out})
		})

	addTool(server, "yaaif_mcp_deployment_status", "Get MCP deployment status by id.",
		schemaObject(map[string]any{
			"deployment_id": map[string]any{"type": "string"},
		}, "deployment_id"),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			id, err := requireString(args, "deployment_id")
			if err != nil {
				return nil, nil, err
			}
			var out any
			if err := r.api.APIJSON(ctx, "GET", "/api/mcp-deployments/"+url.PathEscape(id), nil, &out); err != nil {
				return nil, nil, err
			}
			return textResult("Fetched MCP deployment.", map[string]any{"deployment": out})
		})

	addTool(server, "yaaif_mcp_deployment_logs", "Fetch MCP deployment logs.",
		schemaObject(map[string]any{
			"deployment_id": map[string]any{"type": "string"},
			"tail":          map[string]any{"type": "number"},
		}, "deployment_id"),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			id, err := requireString(args, "deployment_id")
			if err != nil {
				return nil, nil, err
			}
			q := url.Values{}
			if tail, ok := args["tail"].(float64); ok && tail > 0 {
				q.Set("tail", fmt.Sprintf("%d", int(tail)))
			}
			path := "/api/mcp-deployments/" + url.PathEscape(id) + "/logs"
			if enc := q.Encode(); enc != "" {
				path += "?" + enc
			}
			var out any
			if err := r.api.APIJSON(ctx, "GET", path, nil, &out); err != nil {
				return nil, nil, err
			}
			return textResult("Fetched MCP deployment logs.", map[string]any{"logs": out})
		})

	addTool(server, "yaaif_mcp_link_or_create", "Idempotently link/create an external MCP tool in the tenant catalog (fallback when endpoint already runs).",
		schemaObject(map[string]any{
			"name":             map[string]any{"type": "string"},
			"description":      map[string]any{"type": "string"},
			"endpoint":         map[string]any{"type": "string"},
			"transport_type":   map[string]any{"type": "string"},
			"remote_tool_name": map[string]any{"type": "string"},
			"server_id":        map[string]any{"type": "string"},
			"enabled":          map[string]any{"type": "boolean"},
			"timeout_seconds":  map[string]any{"type": "number"},
			"headers":          map[string]any{"type": "object"},
			"env":              map[string]any{"type": "object"},
		}, "name", "endpoint"),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			name, err := requireString(args, "name")
			if err != nil {
				return nil, nil, err
			}
			endpoint, err := requireString(args, "endpoint")
			if err != nil {
				return nil, nil, err
			}
			timeout := 60
			if t, ok := args["timeout_seconds"].(float64); ok && t > 0 {
				timeout = int(t)
			}
			body := map[string]any{
				"name":             name,
				"description":      strArg(args, "description"),
				"endpoint":         endpoint,
				"transport_type":   firstNonEmpty(strArg(args, "transport_type"), "HTTP"),
				"remote_tool_name": firstNonEmpty(strArg(args, "remote_tool_name"), name),
				"enabled":          boolArg(args, "enabled", true),
				"timeout_seconds":  timeout,
				"command":          "",
				"command_args":     []string{},
				"env":              mapArg(args, "env"),
				"headers":          mapArg(args, "headers"),
			}
			if serverID := strArg(args, "server_id"); serverID != "" {
				body["server_id"] = serverID
			}
			var out any
			if err := r.api.AgentJSON(ctx, "POST", "/api/mcp-tools/link-or-create", body, &out); err != nil {
				return nil, nil, err
			}
			return textResult(fmt.Sprintf("Linked/created MCP tool %s.", name), map[string]any{"result": out})
		})

	addTool(server, "yaaif_mcp_server_refresh", "Refresh tools from a registered external MCP server.",
		schemaObject(map[string]any{
			"server_id": map[string]any{"type": "string"},
		}, "server_id"),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			serverID, err := requireString(args, "server_id")
			if err != nil {
				return nil, nil, err
			}
			var out any
			path := "/api/mcp-tools/servers/" + url.PathEscape(serverID) + "/refresh"
			if err := r.api.AgentJSON(ctx, "POST", path, map[string]any{}, &out); err != nil {
				return nil, nil, err
			}
			return textResult("Refreshed MCP server tools.", map[string]any{"result": out})
		})

	addTool(server, "yaaif_mcp_tools_list", "List external MCP tools in the tenant catalog.",
		schemaObject(map[string]any{
			"q": map[string]any{"type": "string"},
		}),
		func(ctx context.Context, args map[string]any) (*mcp.CallToolResult, map[string]any, error) {
			path := "/api/mcp-tools"
			if q := strArg(args, "q"); q != "" {
				path += "?q=" + url.QueryEscape(q)
			}
			var out any
			if err := r.api.AgentJSON(ctx, "GET", path, nil, &out); err != nil {
				return nil, nil, err
			}
			return textResult("Listed MCP tools.", map[string]any{"result": out})
		})
}

func mustGetwd() string {
	wd, err := os.Getwd()
	if err != nil {
		return "."
	}
	return wd
}

func copyDir(src, dst string) error {
	return filepath.Walk(src, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(src, path)
		if err != nil {
			return err
		}
		if rel == ".git" || strings.HasPrefix(rel, ".git"+string(os.PathSeparator)) {
			if info.IsDir() {
				return filepath.SkipDir
			}
			return nil
		}
		target := filepath.Join(dst, rel)
		if info.IsDir() {
			return os.MkdirAll(target, 0o755)
		}
		data, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		return os.WriteFile(target, data, info.Mode())
	})
}
