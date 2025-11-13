USE dw
GO

CREATE TABLE dbo.{REPLACE_VALUE_TARGET_TABLE_NAME}
(
	[{REPLACE_VALUE_SURROGATE_KEY_NAME}] [bigint] IDENTITY(1,1)

------------- insert attribute/measure columns -------------
	,[column1] [varchar](255) NOT NULL
	,[column2] [int] NOT NULL
------------------------------------------------------------

------------- columns for facts ----------------------------
	--,[update_hash] [varbinary](64) NOT NULL
------------------------------------------------------------

------------- columns for dims -----------------------------
	,[type1_hash] [varbinary](64) NOT NULL
	,[type2_hash] [varbinary](64) NOT NULL
	,[effective_start_datetime] [datetime] NOT NULL
	,[effective_end_datetime] [datetime] NOT NULL
	,[is_current] [bit] NOT NULL
------------------------------------------------------------
	
------------- audit columns --------------------------------
	,[nk_hash] [varbinary](64) NOT NULL
	,[last_updated_datetime] [datetime] NOT NULL CONSTRAINT [DF_{REPLACE_VALUE_TARGET_TABLE_NAME}_last_updated_datetime] DEFAULT GETDATE()
	,[load_datetime] [datetime] NOT NULL CONSTRAINT [DF_{REPLACE_VALUE_TARGET_TABLE_NAME}_load_datetime] DEFAULT GETDATE()
------------------------------------------------------------
	,CONSTRAINT PK_dbo_{REPLACE_VALUE_TARGET_TABLE_NAME} PRIMARY KEY CLUSTERED ({REPLACE_VALUE_SURROGATE_KEY_NAME})
)


/****************************************************
	INSERT UNKNOWN MEMBER FOR DIMENSIONS ONLY
****************************************************/

EXEC ADMIN.usp_update_default_dimension_member 'dbo', '{REPLACE_VALUE_TARGET_TABLE_NAME}'; --Specify target table name here