## Overview
- Starter kit for a Kimball-style data warehouse that keeps the top-level guidance brief but points to detailed docs for deeper dives.

## Code & Template Layout
- `sql/` holds reusable warehouse assets, with `sql/templates/` for DDL and stored-proc blueprints (e.g., table/procedure scaffolds) and `sql/admin/security/` for operational scripts such as role generation.
- Reference materials live under `docs/`, including `docs/design.md` for the layer model. The project root houses the high-level README.

## What to Learn Next
- Review warehouse layering conventions in `docs/design.md` and the SQL templates to see how hashes, audit columns, and MERGE patterns support slowly changing dimensions and fact maintenance.
- Use `docs/sources.md` as a checklist when adding new ingestions so staging aligns to the security posture in `security.md`.
- Explore logging and security automation templates (e.g., `sql/templates/template-create-logging-infrastructure.sql` and `sql/admin/security/generate-security-roles.sql`) before building pipelines.
