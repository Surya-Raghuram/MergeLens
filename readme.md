# MergeLens 

**MergeLens** is an autonomous, agentic AI code review and refactoring system designed for GitHub Pull Requests.

Unlike standard LLM wrappers that blindly feed diffs into a prompt, MergeLens utilizes a high-performance **C++ static analysis engine**, an asynchronous background worker architecture, and a **LangGraph-powered multi-agent pipeline** to provide deterministic, context-aware, and strictly verified code reviews.

## System Architecture

MergeLens operates as a monorepo containing four distinct, deployable units:

1. **Flutter Web Dashboard:** A control panel for repository management, live execution logs, agent analytics, and configuration.

2. **Python Backend (FastAPI + Arq):** The webhook receiver, LangGraph agent, and async background worker.

3. **Native C++ Analyzer:** A fast, locally compiled CLI tool made to extract Structural-Metrics JSON (AST parsing, cyclomatic complexity, LOC) from code.

4. **Supabase Database:** Manages PostgreSQL storage, user authentication, and run history.

## Tech Stack

### Core Infrastructure

* **Database & Auth:** Supabase (PostgreSQL + Row Level Security + GitHub OAuth)

* **Message Queue & Memory:** Upstash (Serverless Redis) for async task queuing and LangGraph state persistence.

### Backend & AI Orchestration

* **Language:** Python 3.11+

* **Framework:** FastAPI (HTTP routing), Arq (Redis-based async task queue)

* **AI Orchestration:** LangGraph (Stateful multi-agent pipelines), LangChain

* **LLM Engine:** Groq (LLaMA) / Google Gemini API

* **Integrations:** GitHub App API (PyGithub / HTTPX)

### Static Analysis Engine

* **Language:** C++17 or higher

* **Function:** Pre-processes code files to generate dense JSON metadata, heavily reducing LLM token consumption and preventing context-window bloat.

### Frontend Dashboard

* **Framework:** Flutter (Web target)

* **State Management:** Riverpod (or Provider)

* **Client:** Supabase Flutter SDK

## The Agentic Pipeline (LangGraph)

When a review is triggered, the codebase is processed through a strict, self-correcting topology:

1. **Supervisor Node:** Analyzes the file extensions and metrics from the C++ analyzer, routing tasks to specialized agents (e.g., C++ files to the Systems Agent, Dart files to the UI Agent).

2. **Specialist Subgraphs:** Each language specialist receives the file diff *and* the structural metrics as grounding context. They emit structured Pydantic models (File, Line, Severity, Message) rather than free-text.

3. **Verifier Node:** Collects all specialist outputs. It actively reconciles overlapping comments, drops duplicate feedback, and filters out low-confidence hallucinations.

4. **Self-Correction:** If the verifier detects fatal contradictions, it cycles the state back to the specialists for revision before anything is committed to GitHub.

## Request Lifecycle (End-to-End)

1. **Webhook Ingestion:** A developer opens a PR. GitHub fires an event to the FastAPI backend.

2. **Instant Acknowledge:** FastAPI verifies the HMAC-SHA256 signature, enqueues an asynchronous job on Redis (via `arq`), and instantly returns `202 Accepted` to prevent GitHub webhook timeouts.

3. **Data Fetching:** The `arq` worker exchanges the GitHub App ID for a short-lived token and fetches the PR diffs.

4. **Native Processing:** The worker invokes the **C++ Analyzer** as a subprocess against the changed files, bounding execution with strict memory and time limits.

5. **AI Execution:** The parsed JSON metrics and raw diffs are fed into the **LangGraph pipeline**.

6. **Publishing:** The worker publishes the finalized, verified comments to the PR via the GitHub REST API and logs the entire state trajectory to Supabase.

7. **Real-time UI:** The Flutter dashboard reads the updated Supabase tables via RLS, displaying live metrics and review history to the user.

## Architecture:

* **GitHub App over PAT:** Utilizes scoped, revocable installation tokens (multi-tenant) instead of hardcoded Personal Access Tokens, demonstrating enterprise-grade security architecture.

* **Decoupled Job Queue:** Ensures LLM latency (which can take 30-90s) never blocks the main HTTP thread, completely bypassing GitHub's strict 10-second webhook timeout.

* **C++ Subprocess Sandboxing:** Offloads heavy string manipulation and AST parsing to native code. This prevents Python GIL bottlenecks and isolates potentially unsafe file parsing from the main worker process.

* **Dual Identity Systems:** Supabase handles *human* dashboard authentication via OAuth, while GitHub App private keys strictly handle *backend* machine-to-machine API access. The two are never conflated.

## Deployment route:

MergeLens is architected to be highly scalable but is currently deployed utilizing generous free-tier cloud services:

* **Backend Engine (Render or Hugging Face Spaces):** Deployed as a single Docker container. A process manager (`supervisord`) is used to run both the FastAPI Uvicorn server and the `arq` worker concurrently in the same free-tier instance, sharing access to the compiled C++ binary.

* **State & Queue (Upstash):** A free serverless Redis instance manages both the `arq` queue and LangGraph's checkpointer memory.

* **Database (Supabase):** Free tier PostgreSQL handles user configuration, review run history, and Row Level Security.

* **Frontend UI (Firebase Hosting / Vercel):** The compiled Flutter Web app is deployed to a global CDN for low-latency dashboard access.

## Repository Structure

```
mergelens/
├── backend/                  # Python monorepo root
│   ├── api/                  # FastAPI routers (HTTP layer only)
│   ├── services/             # Business logic & orchestration
│   ├── agents/               # LangGraph graphs and node implementations
│   ├── integrations/         # GitHub, Supabase, and Subprocess wrappers
│   ├── core/                 # Config, logging, auth security
│   ├── models/               # Pydantic schemas
│   ├── workers/              # Arq worker entrypoints
│   └── main.py               # Uvicorn entrypoint
├── analyzer/                 # C++ Source Code
│   ├── src/                  # Parsing logic, metric calculations
│   ├── include/              # Headers
│   └── CMakeLists.txt        # Build configuration
├── dashboard/                # Flutter Web App
│   ├── lib/                  # UI, state management, Supabase client
│   └── web/                  # Web entrypoint
├── docker/                   # Dockerfiles and supervisord configs
└── README.md

```