USE dw
GO

CREATE PROCEDURE [dbo].[usp_action_table]
    @packagename    VARCHAR(100)
   ,@execution_guid VARCHAR(100)
/******************************************************************************************
** Object: table name
** Description: short description
** Author: Developer Name
** Date:  Created Date
** Execution command: code to execute
********************************************************************************************
** Change History
********************************************************************************************
** No     Date         Author         Description
** ----    --------     --------       ------------------------------------
** 1       
********************************************************************************************/

AS

DECLARE @v_start_time DATETIME = GETDATE()
EXEC [admin].usp_update_default_dimension_member @schema = 'dbo', @table = '{replace_value_target_table_name}';

SET XACT_ABORT ON;
BEGIN TRY

-- if USP is run manually, write a row to etl_audit
IF @execution_guid IS NULL
BEGIN
    DECLARE @sproc_name varchar(100);

    SELECT @sproc_name = s.name + '.' + o.name
        FROM sys.objects o
        JOIN sys.schemas s ON o.schema_id = s.schema_id
        WHERE o.object_id = @@PROCID;

    DECLARE @user_id varchar(100) = SYSTEM_USER
    DECLARE @machinename nvarchar(100) = @@SERVERNAME
    SET @execution_guid = '{' + CAST(NEWID() AS varchar(100)) + '}'
    INSERT INTO edw.admin.etl_audit (packagename, machinename, package_id, sproc_name, userid, execution_guid, start_time)
    VALUES ('Manual', @machinename, -1, @sproc_name, @user_id, @execution_guid, @v_start_time);
END

BEGIN TRANSACTION;

/**********************************************
    CREATE TEMPORARY TABLE TO APPLY TRANSFORMATION
**********************************************/
WITH cte_main AS (

------ insert sql query AS a CTE for transformations ------- 
SELECT 
     ISNULL(REPLACE(column1,'-', '00'),'unknown') AS column1
    ,ISNULL(column2,-1) AS column2
FROM {REPLACE_VALUE_SOURCE_TABLE_NAME}
------------------------------------------------------------

)
/****************************************************
    APPLY HASHES FOR TYPE 1 & 2 COMPARISONS
****************************************************/

SELECT *
,CAST(HASHBYTES('sha2_256',CONCAT_WS('|',
------ insert columns that should receive Type 1 updates ------- 
     column1
    ,column2
    )
) AS VARBINARY(64)) AS type1_hash
,CAST(HASHBYTES('SHA2_256',CONCAT_WS('|',
------ insert columns that should receive Type 2 updates ------- 
     column3
    ,column4
    )
) AS VARBINARY(64)) AS type2_hash
,CAST(HASHBYTES('SHA2_256',CONCAT_WS('|',{REPLACE_VALUE_NATURAL_KEYS})) AS VARBINARY(64)) AS nk_hash    /* add natural key column or columns concatenated */
INTO #{REPLACE_VALUE_TARGET_TABLE_NAME}                            /* name temp table #destination_table_name eg. #dim_gl_entry */
--------------------------------------------------------------
FROM cte_main;

/****************************************************
    CREATE TEMPORARY TABLE TO TRACK MERGE OUTPUT ACTIONS
****************************************************/

DROP TABLE IF EXISTS #merge_output
CREATE TABLE #merge_output(action_type nvarchar(100))

DECLARE @CurrentDateTime DATETIME = GETDATE();     /* set current date/time for timestamping */

/****************************************************
    TYPE 1 UPDATE & NEW MEMBERS
****************************************************/

MERGE INTO edw.dbo.{REPLACE_VALUE_TARGET_TABLE_NAME} AS tgt            /* change name of target table to reflect destination */
USING #{REPLACE_VALUE_TARGET_TABLE_NAME} AS src                        /* change name of temp table to reflect temp table above */
    ON src.nk_hash = tgt.nk_hash
WHEN NOT MATCHED THEN 
    INSERT VALUES (
------ insert columns for insert -------         
     src.column1
    ,src.column2    
----------------------------------------
/* Audit and hashing columns */
    ,src.type1_hash
    ,src.type2_hash    
    ,'1900-01-01'
    ,'9999-12-31'
    ,1
    
    ,src.nk_hash
    ,@CurrentDateTime
    ,@CurrentDateTime
    )     
WHEN MATCHED AND tgt.type1_hash <> src.type1_hash
THEN UPDATE SET
    
------ insert columns for update -------     
    tgt.column1 = src.column1
    ,tgt.column2 = src.column2
----------------------------------------

/* Audit and hashing columns */
    ,tgt.type1_hash = src.type1_hash
    ,tgt.last_updated_datetime = @CurrentDateTime
OUTPUT $ACTION AS action_type
INTO #merge_output;

/****************************************************
    TYPE 2 UPDATE - DELETE IF ONLY TYPE 1
****************************************************/

/* Define records that should receive Type 2 updates */
DROP TABLE IF EXISTS #type2;

SELECT
     tgt.{REPLACE_VALUE_SURROGATE_KEY_NAME} --Surrogate key of record to be expired
    ,src.* --All columns from incoming data
INTO #type2
FROM edw.dbo.{REPLACE_VALUE_TARGET_TABLE_NAME} tgt
JOIN #{REPLACE_VALUE_TARGET_TABLE_NAME} src
    ON tgt.nk_hash = src.nk_hash
WHERE tgt.is_current = 1 AND tgt.type2_hash <> src.type2_hash;

/* Expire old member */
UPDATE tgt
SET
     tgt.is_current = 0
    ,tgt.effective_end_datetime = @CurrentDateTime
    ,tgt.last_updated_datetime = @CurrentDateTime
OUTPUT 'UPDATE' INTO #merge_output
FROM edw.dbo.{REPLACE_VALUE_TARGET_TABLE_NAME} tgt
JOIN #type2 src
    ON tgt.{REPLACE_VALUE_SURROGATE_KEY_NAME} = src.{REPLACE_VALUE_SURROGATE_KEY_NAME};

/* Add new member */
INSERT INTO edw.dbo.{REPLACE_VALUE_TARGET_TABLE_NAME} (
------ insert columns for update -------
     column1
    ,column2
----------------------------------------

/* Audit and hashing columns */
    ,type1_hash
    ,type2_hash    
    ,effective_start_datetime
    ,effective_end_datetime
    ,is_current

    ,nk_hash
    ,last_updated_datetime
    ,load_datetime
    )
OUTPUT 'INSERT' INTO #merge_output
SELECT
------ insert columns for update -------
     column1
    ,column2
----------------------------------------

/* Audit and hashing columns */    
    ,type1_hash
    ,type2_hash
    ,@CurrentDateTime    
    ,'9999-12-31'
    ,1

    ,nk_hash
    ,@CurrentDateTime
    ,@CurrentDateTime
    
FROM #type2;

/****************************************************
    OUTPUT ACTIONS AND INSERT COUNTS TO AUDIT TABLE
****************************************************/

SELECT
     action_type
    ,count(*) AS cnt
INTO #audit_counts
FROM #merge_output
GROUP BY action_type;


UPDATE edw.admin.etl_audit
     SET update_count = (SELECT cnt FROM #audit_counts WHERE action_type = 'UPDATE')
        ,insert_count = (SELECT cnt FROM #audit_counts WHERE action_type = 'INSERT')
        ,end_time = CASE WHEN @sproc_name IS NOT NULL THEN GETDATE() ELSE end_time END -- update end_time only if USP is run manually
WHERE execution_guid = @execution_guid;

COMMIT TRANSACTION;
END TRY

BEGIN CATCH
    DECLARE @v_end_time DATETIME = GETDATE()
    DECLARE @v_seconds_ran INT = DATEDIFF(second, @v_start_time, @v_end_time)
    DECLARE @v_Error [INT] = 100000
    DECLARE @v_DB [NVARCHAR](100) = DB_NAME()
    DECLARE @v_Obj [NVARCHAR](100) = OBJECT_NAME(@@PROCID)
    DECLARE @v_App [NVARCHAR](100) = APP_NAME()
    DECLARE @v_User [NVARCHAR](100) = ISNULL(ORIGINAL_LOGIN(), USER_NAME()) 
    DECLARE @v_SPID [NVARCHAR](100) = CONVERT([NVARCHAR](25), @@SPID) 
    DECLARE @v_server_name [NVARCHAR](100) = @@SERVERNAME
    DECLARE @v_MSG [NVARCHAR](1000) = CONVERT(NVARCHAR(2500), 
            'Error: ' + CONVERT([NVARCHAR](255), ISNULL(ERROR_NUMBER(), -1)) + 
            ' Severity: ' + CONVERT([NVARCHAR](255), ISNULL(ERROR_SEVERITY(), -1)) +
            ' State: ' + CONVERT([NVARCHAR](255), ISNULL(ERROR_STATE(), -1)) +
            ' Line: ' +  CONVERT([NVARCHAR](255), ISNULL(ERROR_LINE(), -1)) +
            ' Procedure: ' + CONVERT([NVARCHAR](255), ISNULL(ERROR_PROCEDURE(), @v_Obj)) +
            ' MSG: ' + ISNULL(ERROR_MESSAGE(), ''))
;
        
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    EXEC [admin].[usp_edw_error_log_add]
      @p_Error_ID              = @v_Error
     ,@p_seconds_ran           = @v_seconds_ran
     ,@p_DB                    = @v_DB
     ,@p_Obj                   = @v_Obj
     ,@p_App                   = @v_App
     ,@p_packagename           = @packagename
     ,@p_User                  = @v_User    
     ,@p_error_msg             = @v_MSG
     ,@p_server_name           = @v_server_name
     ,@p_SPID                  = @v_SPID
     ,@p_execution_guid          = @execution_guid
    ;
    THROW;
END CATCH;
GO