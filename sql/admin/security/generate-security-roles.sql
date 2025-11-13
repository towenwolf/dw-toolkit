/* generate roles */
SELECT 'IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N''' + dp.name + ''')
CREATE ROLE ' + QUOTENAME(dp.name) + ';'
FROM sys.database_principals AS dp
WHERE dp.type = 'R' AND dp.name <> 'public';

/*add role members*/
SELECT 'IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members rm
    JOIN sys.database_principals r ON r.principal_id = rm.role_principal_id AND r.name = N''' + r.name + '''
    JOIN sys.database_principals m ON m.principal_id = rm.member_principal_id AND m.name = N''' + m.name + '''
) ALTER ROLE ' + QUOTENAME(r.name) + ' ADD MEMBER ' + QUOTENAME(m.name) + ';'
FROM sys.database_role_members rm
JOIN sys.database_principals r ON r.principal_id = rm.role_principal_id
JOIN sys.database_principals m ON m.principal_id = rm.member_principal_id
WHERE r.name <> 'public' AND m.type IN ('S','U','G');


/* generate explicit GRANT/DENY (avoid duplicates) */
SELECT DISTINCT
       CASE dp.state WHEN 'G' THEN 'GRANT ' WHEN 'D' THEN 'DENY ' WHEN 'W' THEN 'GRANT ' END
       + dp.permission_name + ' ON '
       + CASE dp.class_desc
            WHEN 'OBJECT_OR_COLUMN' THEN
                 QUOTENAME(OBJECT_SCHEMA_NAME(dp.major_id)) + '.' + QUOTENAME(OBJECT_NAME(dp.major_id))
                 + CASE WHEN dp.minor_id = 0
                        THEN ''
                        ELSE '(' + QUOTENAME(COL_NAME(dp.major_id, dp.minor_id)) + ')'
                   END
            WHEN 'SCHEMA'   THEN 'SCHEMA::'   + QUOTENAME(SCHEMA_NAME(dp.major_id))
            WHEN 'DATABASE' THEN 'DATABASE::' + QUOTENAME(DB_NAME())
            ELSE dp.class_desc + '::' + CAST(dp.major_id AS NVARCHAR(20))  -- rare classes; extend if needed
         END
       + ' TO ' + QUOTENAME(USER_NAME(dp.grantee_principal_id))
       + CASE WHEN dp.state = 'W' THEN ' WITH GRANT OPTION' ELSE '' END
       + ';'
FROM sys.database_permissions AS dp
WHERE dp.grantee_principal_id > 0
  AND USER_NAME(dp.grantee_principal_id) NOT IN ('dbo','guest','INFORMATION_SCHEMA','sys');

