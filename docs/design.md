# Data Warehouse Template Design

## Purpose
- Provide a ready-to-use warehouse layout that works on any platform.
- Keep every component independent so teams can plug in their own tools.

## Layers
- **Raw:** land source data with no changes.
- **Staging:** clean names and data types.
- **Core:** build facts and dimensions.
- **Serving:** publish marts and metrics.

## Components
- **SQL:** ANSI-first queries, no vendor features.
- **Orchestration:** abstract task list that maps to any scheduler.
- **Config:** simple YAML/JSON for datasets, SLAs, owners.

## How to Use
1. Copy the repo and review folders.
2. Load sources into the raw area with your ingestion tool.
3. Build staging and core SQL using the templates.
4. Create serving models for your consumers.
5. Wire the orchestration hooks into the scheduler you prefer.

## Guidelines
- Keep platform-specific code outside this template.
- Add adapters only when needed and document them.
- Keep layer ownership and environment variables in README files.

## Measures of Success
- Setup takes less than a sprint.
- Switching warehouse engines requires minimal edits.
- New contributors understand the layout after one read-through.
