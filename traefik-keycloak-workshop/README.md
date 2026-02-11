# Traefik + Keycloak Workshop — Workflow App

## Project Goal

Build a **Workflow application** with a full infrastructure stack, where:

- **Traefik** serves as the reverse-proxy / API gateway — all services available under a single address (e.g. `*.localhost`)
- **Keycloak** serves as the identity provider (IdP) — authentication, roles, Google OAuth integration
- **Workflow App** is a sample service demonstrating role-based access control (RBAC)

---

## Workflow Application Overview

A simple application for managing workflows. Each workflow is a document that moves through stages: **Draft → Submitted → Approved / Rejected**.

### User Roles

| Role | Permissions |
|------|------------|
| `creator` | Create new workflows, edit own workflows in Draft status, submit for approval |
| `approver` | View all workflows, approve or reject (from Submitted status) |
| `viewer` | View all workflows (read-only) |

### Workflow Statuses

```
Draft  ──▶  Submitted  ──▶  Approved
                       ──▶  Rejected
```

### Data Model (simplified)

```
Workflow {
  id: UUID
  title: string
  description: string
  status: "draft" | "submitted" | "approved" | "rejected"
  createdBy: string (user ID from Keycloak)
  createdAt: datetime
  updatedAt: datetime
  decidedBy: string | null
  decisionComment: string | null
}
```

---

## Architecture

```
                    ┌─────────────────────────────────┐
                    │           browser                │
                    └──────────────┬──────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────────┐
                    │       Traefik (gateway)          │
                    │       traefik.localhost           │
                    │       :80 / :443                  │
                    └──┬──────────┬───────────┬───────┘
                       │          │           │
          ┌────────────▼──┐  ┌───▼────────┐  ┌▼──────────────┐
          │   Keycloak     │  │  Frontend  │  │  Backend API  │
          │  auth.localhost│  │ app.localhost│ │ api.localhost  │
          │   :8080        │  │   :3000    │  │   :8000       │
          └───────┬────────┘  └────────────┘  └───────┬───────┘
                  │                                   │
                  │  ┌────────────────────────────────┤
                  │  │                                │
                  │  │  service-to-service (JWT/mTLS) │
                  │  │                                ▼
                  │  │                  ┌──────────────────────┐
                  │  │                  │ Notification Service │
                  │  │                  │      (internal)      │
                  │  │                  └──────────────────────┘
                  │  │                                │
                  ▼  ▼                                │
          ┌───────────────────────────────────────────┘
          │
  ┌───────▼───────┐
  │  PostgreSQL    │
  │   (database)   │
  └───────────────┘
```

### Technology Stack

| Component | Technology |
|-----------|-----------|
| Gateway / Reverse Proxy | **Traefik v3** |
| Identity Provider | **Keycloak 24+** |
| Backend API | **Python (FastAPI)** |
| Frontend | **React (Vite)** |
| Database (app) | **PostgreSQL 16** |
| Database (Keycloak) | **PostgreSQL 16** (separate instance or schema) |
| Containerization | **Docker + Docker Compose** |

---

## Learning Plan — Step by Step

The project is divided into **9 stages**. Each stage adds a new layer of knowledge and results in a working application state.

---

### Stage 1: Traefik — First Steps 🚦

**Goal:** Understand what Traefik is, how Docker auto-discovery works, and how to route traffic.

**What we do:**
- [ ] Create `docker-compose.yml` with Traefik
- [ ] Configure the Traefik Dashboard (`traefik.localhost`)
- [ ] Add a simple `whoami` service as a routing test
- [ ] Learn core concepts: **entrypoints**, **routers**, **services**, **middlewares**
- [ ] Add labels in docker-compose for auto-discovery

**You will know:**
- How Traefik automatically discovers Docker containers
- How routing rules work (Host, PathPrefix)
- What the Traefik Dashboard is and how to read it

**Files:**
```
docker-compose.yml
traefik/traefik.yml          # static configuration
```

---

### Stage 2: Keycloak — Setup and Configuration 🔐

**Goal:** Run Keycloak behind Traefik, create a realm, users, and roles.

**What we do:**
- [ ] Add Keycloak to `docker-compose.yml` with PostgreSQL
- [ ] Expose Keycloak through Traefik at `auth.localhost`
- [ ] Create the `workflow` realm
- [ ] Create roles: `creator`, `approver`, `viewer`
- [ ] Create test users and assign roles
- [ ] Create a `public` type client for the frontend

**You will know:**
- What realm, client, and roles are in Keycloak
- How to administer Keycloak through the UI
- How Keycloak issues JWT tokens with roles

**Files:**
```
docker-compose.yml           # extended with Keycloak + DB
keycloak/realm-export.json   # optional configuration export
```

---

### Stage 3: Backend API — FastAPI with Authorization 🐍

**Goal:** Build a workflow REST API with JWT token validation from Keycloak.

**What we do:**
- [ ] Create a FastAPI project with CRUD endpoints for workflows
- [ ] Implement JWT token validation middleware (JWKS from Keycloak)
- [ ] Implement role-based authorization (RBAC)
- [ ] Add PostgreSQL database (SQLAlchemy / SQLModel)
- [ ] Expose the API through Traefik at `api.localhost`

**Endpoints:**

| Method | Path | Role | Description |
|--------|------|------|-------------|
| GET | `/workflows` | all | List workflows (filtered by role) |
| GET | `/workflows/{id}` | all | Workflow details |
| POST | `/workflows` | creator | Create new workflow |
| PUT | `/workflows/{id}` | creator | Edit workflow (draft only, own) |
| POST | `/workflows/{id}/submit` | creator | Submit for approval |
| POST | `/workflows/{id}/approve` | approver | Approve |
| POST | `/workflows/{id}/reject` | approver | Reject |
| GET | `/me` | all | Current user info |

**You will know:**
- How to validate JWT from Keycloak in FastAPI
- How to implement RBAC at the endpoint level
- How Traefik routes traffic to the backend

**Files:**
```
backend/
├── Dockerfile
├── requirements.txt
├── app/
│   ├── main.py
│   ├── auth.py           # JWT validation
│   ├── models.py          # database models
│   ├── schemas.py         # Pydantic schemas
│   ├── routers/
│   │   └── workflows.py
│   └── database.py
```

---

### Stage 4: Frontend — React with OIDC Login 🖥️

**Goal:** Build a user interface with Keycloak login (OIDC/OAuth2).

**What we do:**
- [ ] Create a React application (Vite)
- [ ] Integrate `keycloak-js` or `oidc-client-ts` for login
- [ ] Implement the flow: login → redirect → callback → token
- [ ] Display workflow list, creation form, approval buttons
- [ ] Show/hide UI elements based on roles
- [ ] Expose the frontend through Traefik at `app.localhost`

**You will know:**
- How the OIDC Authorization Code flow with PKCE works
- How to store and refresh tokens in a SPA
- How to attach tokens to API requests

**Files:**
```
frontend/
├── Dockerfile
├── package.json
├── src/
│   ├── App.tsx
│   ├── auth/
│   │   └── keycloak.ts
│   ├── components/
│   │   ├── WorkflowList.tsx
│   │   ├── WorkflowForm.tsx
│   │   └── WorkflowDetail.tsx
│   └── api/
│       └── client.ts
```

---

### Stage 5: Google Login (Social Login) 🌐

**Goal:** Add Google login as an Identity Provider in Keycloak.

**What we do:**
- [ ] Register an application in Google Cloud Console (OAuth 2.0 Client)
- [ ] Configure Google as an Identity Provider in Keycloak
- [ ] Map Google attributes → Keycloak (email, first name, last name)
- [ ] Test the login flow: "Sign in with Google" button
- [ ] Configure a default role for new Google users

**You will know:**
- How Social Login / Identity Brokering works in Keycloak
- How to map attributes between providers
- How to assign default roles to new users

---

### Stage 6: Traefik Middlewares — Security and Optimization 🛡️

**Goal:** Learn Traefik middlewares — rate limiting, CORS, HTTP→HTTPS redirect, headers.

**What we do:**
- [ ] Add `rate-limit` middleware to the API
- [ ] Configure `CORS` headers for the frontend
- [ ] Add `security headers` (HSTS, X-Frame-Options, etc.)
- [ ] Configure `compress` middleware (gzip)
- [ ] Add `retry` and `circuit-breaker` (optional)

**You will know:**
- How to chain multiple middlewares together
- How Traefik protects the application at the gateway level
- How to debug middlewares in the Traefik Dashboard

**Files:**
```
traefik/dynamic/            # dynamic configuration files
├── middlewares.yml
└── tls.yml                 # optional, for HTTPS
```

---

### Stage 7: Secure Service-to-Service Communication 🔗

**Goal:** Secure internal communication between microservices — so that services can call each other in an authenticated and encrypted way.

**Context:** In real-world systems, the backend is not a monolith. We have multiple services that need to communicate with each other. Questions that arise:
- How does Service B know the request really came from Service A, not from an attacker?
- How to encrypt traffic inside the Docker network?
- How to avoid passing user tokens between services?

**What we do:**

#### 7a. Keycloak Service Accounts (Client Credentials Grant)
- [ ] Create a new `notification-service` (simple FastAPI — sends notifications about workflow status changes)
- [ ] Register the service as a `confidential` client in Keycloak
- [ ] Implement the **Client Credentials Grant** flow — the service obtains a token from Keycloak on its own (without a user)
- [ ] Backend API calls notification-service with a service account token
- [ ] Notification-service validates the token and verifies it comes from a trusted client

#### 7b. mTLS — Mutual Certificate Authentication
- [ ] Generate a custom CA (Certificate Authority) and certificates for services
- [ ] Configure Traefik as the TLS termination point with client certificate verification
- [ ] Configure mTLS between Traefik and backend services
- [ ] Test — requests without a client certificate are rejected

#### 7c. Docker Internal Networks — Isolation
- [ ] Create separate Docker networks: `frontend-net`, `backend-net`, `db-net`
- [ ] Frontend can only see Traefik; backend can see Traefik + database
- [ ] Database is not accessible from outside or from the frontend
- [ ] Map rules: which service can talk to which

**New service — notification-service:**

```
notification-service/
├── Dockerfile
├── requirements.txt
└── app/
    ├── main.py
    ├── auth.py              # service account token validation
    └── notifications.py     # notification logic
```

**Communication diagram:**

```
┌──────────────┐   Client Credentials   ┌──────────────┐
│  Backend API │──────── token ────────▶│   Keycloak   │
│  (service A) │◀──── access_token ─────│              │
└──────┬───────┘                        └──────────────┘
       │
       │  request + Bearer token (service account)
       ▼
┌──────────────────────┐
│ Notification Service │──▶ validates token (JWKS)
│     (service B)      │──▶ checks client_id / roles
└──────────────────────┘
```

```
  mTLS (optional):

  ┌────────┐   TLS + client cert   ┌────────────┐
  │Traefik │◄─────────────────────▶│ Backend API│
  │        │   mutual verification │            │
  └────────┘                       └────────────┘
       ▲
       │ TLS + client cert
       ▼
  ┌──────────────────────┐
  │ Notification Service │
  └──────────────────────┘
```

**You will know:**
- The difference between a user token and a service token (Client Credentials vs Authorization Code)
- How services authenticate each other without user involvement
- What mTLS is and when to use it (vs. regular TLS)
- How to isolate Docker networks to limit the blast radius
- How Traefik handles TLS termination and passthrough

---

### Stage 8: Traefik ForwardAuth + Keycloak 🔒

**Goal:** Move authorization to the gateway level — Traefik checks the token before the request reaches the service.

**What we do:**
- [ ] Configure `forwardAuth` middleware in Traefik
- [ ] Create an auth-proxy microservice (or use `oauth2-proxy`)
- [ ] Traefik forwards the request to auth-proxy, which validates the token with Keycloak
- [ ] If the token is valid — the request goes to the service, otherwise → 401
- [ ] Compare this approach with validation inside the backend itself

**You will know:**
- The difference between gateway-level vs. application-level authorization
- How ForwardAuth works in Traefik
- When to use one approach vs. the other

---

### Stage 9: Production — HTTPS, Monitoring, Best Practices 🚀

**Goal:** Prepare a near-production environment.

**What we do:**
- [ ] Configure HTTPS with Let's Encrypt (Traefik ACME)
- [ ] Add monitoring: Prometheus + Grafana (Traefik metrics)
- [ ] Configure logging (Traefik access logs, Keycloak events)
- [ ] Add health-checks to docker-compose
- [ ] Create `.env` and document configuration variables
- [ ] Write a `Makefile` with useful commands

**You will know:**
- How Traefik automatically renews SSL certificates
- How to monitor traffic and service health
- What the best practices are for this stack

---

## Target Directory Structure

```
traefik-keycloak-workshop/
├── README.md                    # this file
├── docker-compose.yml           # main compose file
├── .env                         # environment variables
├── Makefile                     # useful commands
│
├── traefik/
│   ├── traefik.yml              # static configuration
│   └── dynamic/                 # dynamic configuration
│       ├── middlewares.yml
│       └── tls.yml
│
├── keycloak/
│   └── realm-export.json        # realm configuration export
│
├── backend/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app/
│       ├── main.py
│       ├── auth.py
│       ├── models.py
│       ├── schemas.py
│       ├── database.py
│       └── routers/
│           └── workflows.py
│
├── notification-service/         # internal service (Stage 7)
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app/
│       ├── main.py
│       ├── auth.py              # service account token validation
│       └── notifications.py
│
├── certs/                        # mTLS certificates (Stage 7)
│   ├── ca.pem
│   ├── ca-key.pem
│   ├── backend.pem
│   ├── backend-key.pem
│   └── generate-certs.sh
│
└── frontend/
    ├── Dockerfile
    ├── package.json
    └── src/
        ├── App.tsx
        ├── auth/
        │   └── keycloak.ts
        ├── components/
        └── api/
            └── client.ts
```

---

## Glossary

| Term | Description |
|------|-------------|
| **Reverse Proxy** | An intermediary server that accepts requests from clients and forwards them to the appropriate backend services |
| **Entrypoint** | A Traefik entry point (port it listens on) |
| **Router** | A Traefik rule that decides where to route a request (based on Host, Path, Headers) |
| **Service** | The target service in Traefik that receives the request |
| **Middleware** | An intermediary layer in Traefik that modifies the request/response (auth, rate-limit, headers) |
| **Realm** | An isolated space in Keycloak — a separate pool of users, roles, and clients |
| **Client** | An application registered in Keycloak that can request authentication |
| **OIDC** | OpenID Connect — an authentication protocol built on top of OAuth 2.0 |
| **JWT** | JSON Web Token — a self-contained token carrying user data |
| **JWKS** | JSON Web Key Set — public keys for verifying JWT signatures |
| **PKCE** | Proof Key for Code Exchange — an OAuth flow security enhancement for SPAs |
| **RBAC** | Role-Based Access Control — access control based on user roles |
| **ForwardAuth** | A Traefik middleware that delegates authentication to an external service |
| **Identity Brokering** | Keycloak acting as an intermediary between a user and an external provider (e.g. Google) |
| **Client Credentials Grant** | An OAuth 2.0 flow where a service (not a user) authenticates with its own credentials (client_id + secret) and receives an access token |
| **Service Account** | A service account in Keycloak — an identity assigned to an application/service, not a person |
| **mTLS** | Mutual TLS — both sides of a connection (client and server) present certificates and mutually verify each other |
| **TLS Termination** | Traefik decrypts TLS traffic and forwards it as HTTP (or re-encrypts — re-encryption) |
| **TLS Passthrough** | Traefik forwards encrypted TLS traffic without decrypting — the target service handles TLS itself |
| **CA (Certificate Authority)** | A certification authority — an entity that issues digital certificates, used to build a chain of trust |
| **Network Segmentation** | Dividing a network into isolated segments — limits which services can communicate with each other |

---

## Getting Started

```bash
# We will build the project stage by stage.
# Start with Stage 1 — launching Traefik.

# Useful commands:
docker compose up -d          # start all services
docker compose logs -f        # follow logs
docker compose down           # stop services
docker compose ps             # container status
```

---

## Prerequisites

- [x] Docker + Docker Compose v2
- [x] Browser (Chrome / Firefox)
- [x] Code editor (VS Code)
- [ ] Google Cloud account (for Stage 5 — Social Login)
- [ ] Domain (optional, for Stage 9 — HTTPS with Let's Encrypt)

---

> **Note:** Each stage is designed so you can complete it independently. If something doesn't work — go back to the previous stage and make sure everything is correct.
>
> Good luck! 🚀
