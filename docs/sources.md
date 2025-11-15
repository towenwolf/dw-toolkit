# Source Types

## Secure FTP (SFTP)
Use SFTP for batch file drops when a partner system cannot connect directly to the warehouse. Provision unique SSH keys per partner, enforce IP allow lists, and checksum every file before ingesting so tampering or replay attacks are detectable. Capture arrival metadata (filename, bytes transferred, hash) in staging logs for auditability.

## Database Connections
Direct database links (e.g., SQL Server, Postgres) suit high-volume, structured extracts. Use read-only credentials scoped to the specific schemas, and throttle queries with incremental watermarks to avoid locking source OLTP workloads. Always encrypt connections (TLS/SSL) and document CDC or snapshot cadence in the pipeline README.

## Blob/Object Storage
Cloud buckets (Azure Blob, S3, GCS) provide durable landing zones for semi-structured data. Require server-side encryption, enable versioning, and set lifecycle rules so raw data is retained only as long as compliance demands. Use signed URLs or service principals rather than embedding access keys in code, and mirror folder naming conventions to warehouse layers for traceability.

## API Endpoints
REST or GraphQL APIs supply near-real-time data but often enforce rate limits. Cache tokens in secure stores, respect retry/backoff headers, and log request ids plus response hashes to trace anomalies. When possible, request filtered fields to minimize payload size and exposure, and wrap API calls inside idempotent jobs so partial failures can resume safely.
