# Repository Guidelines

## Project Structure & Module Organization
The `sql/` directory holds the reusable warehouse assets. `sql/templates/` stores DDL and stored-proc blueprints (e.g., `template-create-table.sql`) that should be copied and customized before execution, while `sql/admin/security/` contains operational scripts such as `generate-security-roles.sql`. Reference materials live under `docs/` (see `docs/design.md` for the layer model), and the project root houses the high-level `README.md`.

## Build, Test, and Development Commands
Run templates or admin scripts directly with SQL Server tooling. Example: `sqlcmd -S <server> -d dw -i sql/templates/template-create-table.sql` creates a dimension or fact shell once placeholders are replaced. Use `sqlcmd -S <server> -d master -i sql/admin/security/generate-security-roles.sql` to mirror security in downstream environments. Keep ad-hoc helpers in `scripts/` (create it if missing) so contributors know where to look.

## Coding Style & Naming Conventions
Favor ANSI-standard SQL so templates stay portable; avoid vendor-only syntax unless the limitation is documented inline. Use uppercase keywords, lowercase snake_case identifiers (`stg_customer`, `fact_order`), and prefix schemas explicitly (`dbo`, `raw`, `stg`, `core`, `serv`). Indent multi-line clauses with tabs or four spaces consistently, and align commas as shown in the templates. Default constraints and hashes should follow the `{table}_{column}` pattern already present in `template-create-table.sql`.

## Testing Guidelines
Unit-test transformations by creating throwaway staging tables, loading representative rows, and validating outputs with assertions such as `SELECT COUNT(*)` and hash comparisons. Capture these checks in SQL files under `tests/` and run them via `sqlcmd -S <server> -d dw -i tests/<file>.sql` before opening a pull request. Document any data-quality expectations inside the test scripts so reviewers can trace business logic quickly.

## Commit & Pull Request Guidelines
Match the existing Git history: short, present-tense summaries under ~60 characters (`adding design md`, `organizing repo`). Group related SQL and docs changes in the same commit when they describe the same feature. Pull requests should include a concise description of the warehouse layer touched, sample commands executed, and any configuration impact. Link tracking tickets or paste screenshots of validation queries when UI-facing dashboards are affected, and request a reviewer familiar with the target layer.

## Security & Configuration Notes
Never commit live credentials; parameterize connections via environment variables or your secrets manager. Regenerate security artifacts by running the admin script against production metadata rather than editing grants by hand, and review the output before applying. When sharing configs, scrub tenant-specific schema names so this template stays platform-neutral.
