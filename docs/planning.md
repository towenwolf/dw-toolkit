# Planning: Data Warehouse Template Improvements

## Objectives
- Prioritize improvements that make the template turnkey for new teams while staying platform-neutral.
- Strengthen security and governance defaults to align with the guidance in `security.md`.
- Reduce time-to-first-pipeline by bundling runnable examples and validation checks.

## Near-Term Enhancements (0-1 sprint)
- **Add runnable sample pipeline:** Provide raw → staging → core SQL examples with seed data and a minimal orchestration script to demonstrate the intended flow end-to-end.
- **Document testing patterns:** Add SQL-based data quality checks under `tests/` (row counts, hash consistency, referential integrity) and show how to execute them via `sqlcmd`.
- **Security role regeneration guide:** Expand `sql/admin/security/generate-security-roles.sql` with a short how-to and expected outputs to simplify environment cloning.
- **Setup checklist:** Create a quickstart page that links design, sources, and security docs with a one-page setup sequence.

## Mid-Term Features (1-3 sprints)
- **Parameterized table templates:** Introduce a small templating layer (e.g., environment variables or a Makefile) to fill placeholders in `sql/templates/` for common dimension and fact scaffolds.
- **Metadata-driven orchestration hooks:** Publish a JSON/YAML schema for datasets (owners, SLAs, refresh cadence) and sample adapters for popular schedulers.
- **Data classification tags:** Add optional tagging columns and guidance for PII levels, plus downstream role-based filters in serving models.
- **Sample SCD patterns:** Provide slowly changing dimension examples (Type 1 and 2) with reusable hash/merge logic.

## Longer-Term Ideas (3+ sprints)
- **Pluggable ingestion adapters:** Sketch connectors for common sources (files, APIs, CDC) that map outputs into the raw layer contracts.
- **Observability bundle:** Offer templates for audit/log tables, alert routes, and a lightweight dashboard to monitor load freshness.
- **Benchmark harness:** Include a small dataset and benchmark script to evaluate performance impacts when switching warehouse engines.

## Dependencies & Open Questions
- Which orchestration platforms should be prioritized for sample adapters (Airflow, Dagster, dbt Cloud jobs)?
- Are there preferred secrets managers or key vault patterns we should showcase alongside the security scripts?
- Do consumers require BI-layer examples (Looker/Power BI/Mode) to validate serving models, or is SQL-only sufficient?
