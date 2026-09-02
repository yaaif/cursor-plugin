# Shared helpers for installer shell scripts. Source only.

plugin_version() {
  local root="$1"
  python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' \
    "$root/.cursor-plugin/plugin.json"
}

host_os() {
  case "$(uname -s)" in
    Darwin) echo darwin ;;
    Linux) echo linux ;;
    MINGW*|MSYS*|CYGWIN*) echo win ;;
    *)
      echo "unsupported OS: $(uname -s)" >&2
      return 1
      ;;
  esac
}

host_arch() {
  case "$(uname -m)" in
    arm64|aarch64) echo arm64 ;;
    x86_64|amd64) echo x64 ;;
    *)
      echo "unsupported arch: $(uname -m)" >&2
      return 1
      ;;
  esac
}

runtime_triple() {
  local os="${1:-}"
  local arch="${2:-}"
  if [[ -z "$os" ]]; then
    os="$(host_os)"
  fi
  if [[ -z "$arch" ]]; then
    arch="$(host_arch)"
  fi
  echo "${os}-${arch}"
}

sha256_file() {
  local file="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  else
    echo "need shasum or sha256sum" >&2
    return 1
  fi
}

verify_sha256() {
  local file="$1"
  local expected="$2"
  local actual
  actual="$(sha256_file "$file")"
  if [[ "$actual" != "$expected" ]]; then
    echo "SHA-256 mismatch for $(basename "$file")" >&2
    echo "  expected: $expected" >&2
    echo "  actual:   $actual" >&2
    return 1
  fi
}

abs_path() {
  python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$1"
}

# Compare dotted versions. Prints -1 / 0 / 1.
version_cmp() {
  python3 -c '
import sys
def parts(v):
    out = []
    for p in v.replace("-", ".").split("."):
        if p.isdigit():
            out.append(int(p))
    return out or [0]
a, b = parts(sys.argv[1]), parts(sys.argv[2])
n = max(len(a), len(b))
a += [0] * (n - len(a))
b += [0] * (n - len(b))
print(-1 if a < b else 1 if a > b else 0)
' "$1" "$2"
}

write_dist_checksums() {
  local dir="$1"
  mkdir -p "$dir"
  (
    cd "$dir"
    if command -v shasum >/dev/null 2>&1; then
      find . -maxdepth 1 -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 shasum -a 256
    else
      find . -maxdepth 1 -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum
    fi
  ) >"$dir/SHA256SUMS"
}

home_for_user() {
  local user="$1"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    dscl . -read "/Users/${user}" NFSHomeDirectory 2>/dev/null | awk '{print $2}'
  elif command -v getent >/dev/null 2>&1; then
    getent passwd "$user" | cut -d: -f6
  else
    eval echo "~${user}"
  fi
}
