# Threat model

See also [SECURITY.md](../SECURITY.md).

| Asset | Risk | Mitigation |
|-------|------|------------|
| Access / refresh tokens | Disk theft | `~/.yaaif/cursor/session.json` mode 0600; logout tool |
| Tenant APIs | Over-privileged agent | User OIDC identity + RBAC; same as Admin UI |
| MCP deploy | Malicious image | Operator registry controls; user confirms image tags |
| PKCE callback | Port hijack | Loopback only, random state + verifier |

Out of scope: defending a compromised Cursor host, or replacing YAA\F server-side authorization.
