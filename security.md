# Security Guidelines

## Principles
- Least privilege by default; every login maps to a role scoped to its warehouse layer (raw, stg, core, serv).
- Defense in depth: database ACLs plus OS and network controls; assume scripts may run on shared hosts.
- Audit-first mindset: every ETL proc must log start, end, and errors via the `admin.etl_audit` and `admin.etl_error_log` tables.

## Access Management
1. Create roles per layer (`raw_reader`, `stg_loader`, `core_writer`, `serv_reader`) and grant object-level privileges only to those roles.
2. Map SQL logins or Azure AD groups to the roles; never grant permissions directly to individual logins.
3. Use signed stored procedures for write paths; service accounts execute `dbo.usp_*` loaders without needing table-level grants.
4. Rotate credentials quarterly and store them in a secrets manager; scripts reference connection strings via environment variables.

## Operational Controls
- Enable row counts and hash checks in staging tests (`tests/*.sql`) to detect tampering.
- Run `admin.etl_audit` reviews daily; missing rows imply a loader skipped auditing and should be blocked in CI.
- Deploy firewalls/NSGs so only the ETL subnet can reach the SQL endpoint; analysts connect through bastion jump boxes.
- Encrypt backups and disable ad-hoc SELECT on serving schemas; analysts query through governed views or semantic layers.

## Anti-Exfiltration Practices
- Use parameterized templates (see `sql/templates/`) and forbid string concatenation of schema/table names from user input.
- Validate any export procedure for row limits and strict WHERE clauses; log export requests with requester ID and reason.
- Monitor `sys.dm_audit_actions` for mass exports; alert if result sets exceed expected thresholds.
- Mask PII columns in lower layers and expose only hashed or tokenized versions upstream.

Treat these controls as part of the design checklist for every new template and review them whenever security posture changes.
