USE {REPLACE_VALUE_DATABASE_NAME}
GO

/******************************************************************************************
    Create the admin schema if it does not already exist.
******************************************************************************************/
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = '{REPLACE_VALUE_ADMIN_SCHEMA}')
    EXEC('CREATE SCHEMA {REPLACE_VALUE_ADMIN_SCHEMA}');
GO

/******************************************************************************************
    Audit table captures ETL execution metadata that loaders update as they run.
******************************************************************************************/
IF OBJECT_ID('{REPLACE_VALUE_ADMIN_SCHEMA}.etl_audit', 'U') IS NULL
BEGIN
    CREATE TABLE {REPLACE_VALUE_ADMIN_SCHEMA}.etl_audit
    (
         etl_audit_id          BIGINT IDENTITY(1,1) NOT NULL
        ,packagename           VARCHAR(100)         NOT NULL
        ,machinename           NVARCHAR(100)        NOT NULL
        ,package_id            INT                  NOT NULL CONSTRAINT DF_etl_audit_package_id DEFAULT (-1)
        ,sproc_name            SYSNAME              NOT NULL
        ,userid                VARCHAR(100)         NOT NULL
        ,execution_guid        VARCHAR(100)         NOT NULL
        ,start_time            DATETIME             NOT NULL CONSTRAINT DF_etl_audit_start_time DEFAULT (GETDATE())
        ,insert_count          INT                  NULL
        ,update_count          INT                  NULL
        ,delete_count          INT                  NULL
        ,error_count           INT                  NULL
        ,end_time              DATETIME             NULL
        ,duration_seconds      INT                  NULL
        ,status                NVARCHAR(50)         NULL
        ,created_datetime      DATETIME             NOT NULL CONSTRAINT DF_etl_audit_created_datetime DEFAULT (GETDATE())
        ,modified_datetime     DATETIME             NOT NULL CONSTRAINT DF_etl_audit_modified_datetime DEFAULT (GETDATE())
        ,CONSTRAINT PK_etl_audit PRIMARY KEY CLUSTERED (etl_audit_id)
        ,CONSTRAINT UQ_etl_audit_execution_guid UNIQUE (execution_guid)
    );
END
GO

CREATE OR ALTER TRIGGER {REPLACE_VALUE_ADMIN_SCHEMA}.trg_etl_audit_set_modified
ON {REPLACE_VALUE_ADMIN_SCHEMA}.etl_audit
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE tgt
        SET modified_datetime = GETDATE()
    FROM {REPLACE_VALUE_ADMIN_SCHEMA}.etl_audit tgt
    JOIN inserted i
        ON tgt.etl_audit_id = i.etl_audit_id;
END
GO

/******************************************************************************************
    Error log table keeps detailed exception context per ETL execution.
******************************************************************************************/
IF OBJECT_ID('{REPLACE_VALUE_ADMIN_SCHEMA}.etl_error_log', 'U') IS NULL
BEGIN
    CREATE TABLE {REPLACE_VALUE_ADMIN_SCHEMA}.etl_error_log
    (
         etl_error_log_id  BIGINT IDENTITY(1,1) NOT NULL
        ,error_id          INT                  NOT NULL
        ,execution_guid    VARCHAR(100)         NULL
        ,seconds_ran       INT                  NULL
        ,db_name           NVARCHAR(100)        NULL
        ,object_name       NVARCHAR(100)        NULL
        ,application_name  NVARCHAR(100)        NULL
        ,packagename       VARCHAR(100)         NULL
        ,user_name         NVARCHAR(100)        NULL
        ,error_message     NVARCHAR(2000)       NULL
        ,server_name       NVARCHAR(100)        NULL
        ,spid              NVARCHAR(100)        NULL
        ,logged_datetime   DATETIME             NOT NULL CONSTRAINT DF_etl_error_log_logged_datetime DEFAULT (GETDATE())
        ,CONSTRAINT PK_etl_error_log PRIMARY KEY CLUSTERED (etl_error_log_id)
        ,CONSTRAINT FK_etl_error_log_etl_audit FOREIGN KEY (execution_guid)
            REFERENCES {REPLACE_VALUE_ADMIN_SCHEMA}.etl_audit (execution_guid)
    );
END
GO
