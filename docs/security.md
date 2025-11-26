# Security Guidelines

Use these ten rules as a lightweight, tool-agnostic checklist. Each rule includes brief reasoning so reviewers know why the control matters.

1. **Least privilege roles** – grant access through layer-scoped roles rather than individual accounts because shared roles make entitlements auditable and reduce accidental privilege creep.
2. **Isolated service accounts** – dedicate credentials per automation or team; breaches in one pipeline then stay contained instead of unlocking the entire warehouse.
3. **Secrets stay external** – store passwords and tokens in a secrets vault or environment variables since history shows plaintext configs are a common breach vector.
4. **Signed or wrapped writes** – route mutations through vetted procedures or services so users never need direct table `INSERT/UPDATE/DELETE`, shrinking the attack surface for malicious SQL.
5. **Comprehensive auditing** – require every job to record start/end/error metadata in the logging tables; investigations move faster when you can prove who ran what and when.
6. **Daily review of logs** – a lightweight rotation that scans audit tables for missing entries or spikes in errors catches compromised agents before they exfiltrate data.
7. **Network segmentation** – limit database endpoints to trusted subnets and bastion hosts; most large leaks begin with overly open network paths.
8. **Data minimization in exports** – enforce row limits, parameterized filters, and requester attribution on any export tooling because uncontrolled exports are the fastest path to data loss.
9. **Defense-in-depth testing** – add row-count and hash validations in staging tests so tampering or silent truncation gets caught before results reach consumers.
10. **Protect sensitive columns** – mask or tokenize personal data in upstream layers so even if an agent reaches staging tables, the raw identifiers are never exposed.

Review these rules during design and code review to keep security a first-class concern.
