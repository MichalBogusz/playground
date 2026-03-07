#!/usr/bin/env bash
# keycloak/setup.sh
#
# Configures the Keycloak `workflow` realm via Admin REST API:
#   - Creates realm: workflow
#   - Creates roles: creator, approver, viewer
#   - Creates users: alice (creator), bob (approver), carol (viewer)
#   - Creates OIDC client: workflow-frontend (public)
#
# Usage: ./keycloak/setup.sh
# Requires: curl, jq

set -euo pipefail

KEYCLOAK_URL="${KEYCLOAK_URL:-http://auth.localhost}"
ADMIN_USER="${KEYCLOAK_ADMIN_USER:-admin}"
ADMIN_PASS="${KEYCLOAK_ADMIN_PASSWORD:-admin}"
REALM="workflow"

# ─── Colors ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }

# ─── 1. Get admin token ───────────────────────────────────────────────────────
info "Authenticating as '${ADMIN_USER}' in master realm..."

TOKEN=$(curl -sf \
  -d "client_id=admin-cli" \
  -d "username=${ADMIN_USER}" \
  -d "password=${ADMIN_PASS}" \
  -d "grant_type=password" \
  "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
  | jq -r '.access_token')

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "ERROR: Failed to obtain admin token. Is Keycloak running at ${KEYCLOAK_URL}?"
  exit 1
fi
success "Admin token obtained"

# Helper: call Keycloak Admin API
kc() { curl -sf -H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json" "$@"; }

# ─── 2. Create realm ─────────────────────────────────────────────────────────
info "Creating realm '${REALM}'..."

HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -X POST "${KEYCLOAK_URL}/admin/realms" \
  -d "{
    \"realm\": \"${REALM}\",
    \"displayName\": \"Workflow\",
    \"enabled\": true,
    \"registrationAllowed\": false,
    \"loginWithEmailAllowed\": true,
    \"accessTokenLifespan\": 300
  }")

if [[ "$HTTP" == "201" ]]; then
  success "Realm '${REALM}' created"
elif [[ "$HTTP" == "409" ]]; then
  warn "Realm '${REALM}' already exists — skipping"
else
  echo "ERROR: Unexpected HTTP ${HTTP} when creating realm"
  exit 1
fi

# ─── 3. Create roles ─────────────────────────────────────────────────────────
create_role() {
  local role="$1"
  local description="$2"

  HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/roles" \
    -d "{\"name\": \"${role}\", \"description\": \"${description}\"}")

  if [[ "$HTTP" == "201" ]]; then
    success "Role '${role}' created"
  elif [[ "$HTTP" == "409" ]]; then
    warn "Role '${role}' already exists — skipping"
  else
    echo "ERROR: HTTP ${HTTP} when creating role '${role}'"
    exit 1
  fi
}

info "Creating roles..."
create_role "creator"  "Can create and submit workflow items"
create_role "approver" "Can approve or reject workflow items"
create_role "viewer"   "Read-only access to workflow items"

# ─── 4. Create users ─────────────────────────────────────────────────────────
create_user_with_role() {
  local username="$1"
  local password="$2"
  local role="$3"
  local email="${username}@example.com"

  # Create user
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/users" \
    -d "{
      \"username\": \"${username}\",
      \"email\": \"${email}\",
      \"firstName\": \"${username^}\",
      \"enabled\": true,
      \"credentials\": [{
        \"type\": \"password\",
        \"value\": \"${password}\",
        \"temporary\": false
      }]
    }")

  if [[ "$HTTP" == "409" ]]; then
    warn "User '${username}' already exists — skipping role assignment"
    return
  elif [[ "$HTTP" != "201" ]]; then
    echo "ERROR: HTTP ${HTTP} when creating user '${username}'"
    exit 1
  fi

  success "User '${username}' (${email}) created"

  # Get user ID
  USER_ID=$(kc "${KEYCLOAK_URL}/admin/realms/${REALM}/users?username=${username}&exact=true" \
    | jq -r '.[0].id')

  # Get role representation
  ROLE_REP=$(kc "${KEYCLOAK_URL}/admin/realms/${REALM}/roles/${role}")

  # Assign role
  kc -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/users/${USER_ID}/role-mappings/realm" \
    -d "[${ROLE_REP}]" > /dev/null

  success "Role '${role}' assigned to '${username}'"
}

info "Creating users..."
create_user_with_role "alice" "alice123" "creator"
create_user_with_role "bob"   "bob123"   "approver"
create_user_with_role "carol" "carol123" "viewer"

# ─── 5. Create OIDC client ────────────────────────────────────────────────────
info "Creating OIDC client 'workflow-frontend'..."

HTTP=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/clients" \
  -d '{
    "clientId": "workflow-frontend",
    "name": "Workflow Frontend",
    "description": "Public OIDC client for the React frontend",
    "enabled": true,
    "publicClient": true,
    "standardFlowEnabled": true,
    "directAccessGrantsEnabled": true,
    "redirectUris": ["http://app.localhost/*"],
    "webOrigins": ["http://app.localhost"],
    "protocol": "openid-connect"
  }')

if [[ "$HTTP" == "201" ]]; then
  success "Client 'workflow-frontend' created"
elif [[ "$HTTP" == "409" ]]; then
  warn "Client 'workflow-frontend' already exists — skipping"
else
  echo "ERROR: HTTP ${HTTP} when creating client"
  exit 1
fi

# ─── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}  Keycloak setup complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "  Realm:   ${REALM}"
echo "  Roles:   creator, approver, viewer"
echo ""
echo "  Users:"
echo "    alice / alice123  → creator"
echo "    bob   / bob123    → approver"
echo "    carol / carol123  → viewer"
echo ""
echo "  Client:  workflow-frontend (public OIDC)"
echo ""
echo "  Admin UI: ${KEYCLOAK_URL}/admin/master/console/"
echo ""
