SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_GeneralJournal_ext')
DROP PROCEDURE [dbo].[usp_GeneralJournal_ext]
GO

CREATE PROCEDURE [dbo].[usp_GeneralJournal_ext] (@CDMLocation NVARCHAR(500), @Container NVARCHAR(100), @StorageAcc NVARCHAR(500))
AS
BEGIN
	IF NOT EXISTS (select top 1 1 from sys.database_scoped_credentials where name = 'demoCred')
	BEGIN
		CREATE DATABASE SCOPED CREDENTIAL demoCred
		WITH IDENTITY = 'Managed Identity';
	END

	IF NOT EXISTS (SELECT top 1 1 FROM sys.external_data_sources WHERE NAME='demoExtDS')
	BEGIN
		DECLARE @CreateExtDS NVARCHAR(4000) = N'CREATE EXTERNAL DATA SOURCE demoExtDS
		WITH (
			LOCATION = ''abfss://'+@Container+'@'+@StorageAcc+'.dfs.core.windows.net'',
			CREDENTIAL = demoCred
		);';
		EXEC sp_executesql @tsql = @CreateExtDS;
	END;
	
	IF NOT EXISTS (select top 1 1 from sys.external_file_formats where name = 'csvFileWithHeader')
	BEGIN
		CREATE EXTERNAL FILE FORMAT [csvFileWithHeader]
		WITH (
			FORMAT_TYPE = DELIMITEDTEXT,
			FORMAT_OPTIONS (
				FIELD_TERMINATOR = N',',
				FIRST_ROW=2,
				USE_TYPE_DEFAULT=False
			)
		);
	END

	IF EXISTS (SELECT top 1 1 FROM sys.tables WHERE name='GeneralJournal_Small_Ext')
	BEGIN
		DROP EXTERNAL TABLE [dbo].[GeneralJournal_Small_Ext];
	END

	DECLARE @CreateExtTbl NVARCHAR(4000) = N'CREATE EXTERNAL TABLE [dbo].[GeneralJournal_Small_Ext]
		(
			[JournalName] NVARCHAR(1000),
			[JournalBatchNumber] NVARCHAR(1000),
			[LineNumber] NVARCHAR(1000),
			[AccountName] NVARCHAR(1000),
			[AccountType] NVARCHAR(1000),
			[CreditAmount] FLOAT(24),
			[DebitAmount] FLOAT(24),
			[Currency] NVARCHAR(1000),
			[ExchangeRate] FLOAT(24),
			[Description] NVARCHAR(1000),
			[Invoice] NVARCHAR(1000),
			[IsPosted] NVARCHAR(1000),
			[PostedDate] DATE,
			[PostingLayer] NVARCHAR(1000),
			[OffsetAccountName] NVARCHAR(1000),
			[OffsetAccountType] NVARCHAR(1000),
			[PaymentMethod] NVARCHAR(1000),
			[PaymentDate] DATE
		)
		WITH (
		LOCATION = '''+@CDMLocation+N''',
		DATA_SOURCE = [demoExtDS],
		FILE_FORMAT = [csvFileWithHeader]
		);';
		EXEC sp_executesql @tsql = @CreateExtTbl;
END
GO


