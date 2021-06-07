SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_NycTaxi_External_Table')
DROP PROCEDURE [dbo].[usp_NycTaxi_External_Table]
GO

CREATE PROCEDURE [dbo].[usp_NycTaxi_External_Table] (@CDMLocation NVARCHAR(500), @Container NVARCHAR(100), @StorageAcc NVARCHAR(500))
AS
BEGIN
	IF NOT EXISTS (select top 1 1 from sys.database_scoped_credentials where name = 'demoCred')
	BEGIN
		CREATE DATABASE SCOPED CREDENTIAL demoCred
		WITH IDENTITY = 'Managed Identity';
	END

	IF EXISTS (SELECT top 1 1 FROM sys.external_data_sources WHERE NAME='demoExtDS')
	BEGIN
		DROP EXTERNAL DATA SOURCE demoExtDS;
	END;
	
	DECLARE @CreateExtDS NVARCHAR(4000) = N'CREATE EXTERNAL DATA SOURCE demoExtDS
	WITH (
		LOCATION = ''abfss://'+@Container+'@'+@StorageAcc+'.dfs.core.windows.net'',
		CREDENTIAL = demoCred
	);';
	EXEC sp_executesql @tsql = @CreateExtDS;

	IF NOT EXISTS (select top 1 1 from sys.external_file_formats where name = 'parquetfileformat')
	BEGIN
		CREATE EXTERNAL FILE FORMAT parquetfileformat
		WITH
		(  
    FORMAT_TYPE = PARQUET,
    DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'
		)

		
	END

	IF EXISTS (SELECT top 1 1 FROM sys.tables WHERE name='NycTaxi_External_Table')
	BEGIN
		DROP EXTERNAL TABLE [dbo].[NycTaxi_External_Table];
	END

	DECLARE @CreateExtTbl NVARCHAR(4000) = N'CREATE EXTERNAL TABLE [dbo].[NycTaxi_External_Table]
		(
			[vendor_id] [nvarchar](4000),
			[pickup_datetime] [nvarchar](4000),
			[dropoff_datetime] [nvarchar](4000),
			[store_and_foreward] [nvarchar](4000),
			[rate_code_id] [int],
			[pickup_longitude] [float],
			[pickup_latitude] [float],
			[dropoff_longitude] [float],
			[dropoff_latitude] [float],
			[passenger_count] [int],
			[trip_distance] [decimal](18, 2),
			[fare_amount] [decimal](18, 2),
			[extra] [decimal](18, 2),
			[mta_tax] [decimal](18, 2),
			[tip_amount] [decimal](18, 2),
			[tolls_amount] [decimal](18, 2),
			[ehail_fee] [decimal](18, 2),
			[total_amount] [decimal](18, 2),
			[payment_type] [int],
			[trip_type] [nvarchar](4000)
		)
		WITH (
		LOCATION = '''+@CDMLocation+N''',
		DATA_SOURCE = [demoExtDS],
		FILE_FORMAT = [parquetfileformat]
		);';
		EXEC sp_executesql @tsql = @CreateExtTbl;
END
GO


