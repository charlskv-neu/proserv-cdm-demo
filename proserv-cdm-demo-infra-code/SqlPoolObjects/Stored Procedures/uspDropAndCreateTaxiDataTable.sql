SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'uspDropAndCreateTaxiDataTable')
DROP PROCEDURE [dbo].[uspDropAndCreateTaxiDataTable]
GO

CREATE PROC [dbo].[uspDropAndCreateTaxiDataTable] @table_name [VARCHAR](100) AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	IF EXISTS (SELECT top 1 1 FROM sys.tables WHERE name=@table_name)
    BEGIN
        DECLARE @drop_stmt NVARCHAR(200) = N'DROP TABLE dbo.' + @table_name; 
        EXEC sp_executesql @tsql = @drop_stmt;
		-- DROP TABLE [dbo].[nyctaxidata_large1];
    END

    BEGIN
	DECLARE @create_stmt NVARCHAR(4000) = N'CREATE TABLE dbo.' + @table_name+' 
    (
		[vendor_id] [nvarchar](4000) NULL,
		[pickup_datetime] [nvarchar](4000) NULL,
		[dropoff_datetime] [nvarchar](4000) NULL,
		[store_and_foreward] [nvarchar](4000) NULL,
		[rate_code_id] [int] NULL,
		[pickup_longitude] [float] NULL,
		[pickup_latitude] [float] NULL,
		[dropoff_longitude] [float] NULL,
		[dropoff_latitude] [float] NULL,
		[passenger_count] [int] NULL,
		[trip_distance] [decimal](18, 2) NULL,
		[fare_amount] [decimal](18, 2) NULL,
		[extra] [decimal](18, 2) NULL,
		[mta_tax] [decimal](18, 2) NULL,
		[tip_amount] [decimal](18, 2) NULL,
		[tolls_amount] [decimal](18, 2) NULL,
		[ehail_fee] [decimal](18, 2) NULL,
		[total_amount] [decimal](18, 2) NULL,
		[payment_type] [int] NULL,
		[trip_type] [nvarchar](4000) NULL
	)
	WITH
	(
		DISTRIBUTION = ROUND_ROBIN,
		CLUSTERED COLUMNSTORE INDEX
	)';

	EXEC sp_executesql @tsql = @create_stmt;
	
	END
END
GO