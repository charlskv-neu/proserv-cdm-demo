SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'uspCreateTaxiAggregateTable')
DROP PROCEDURE [dbo].[uspCreateTaxiAggregateTable]
GO

CREATE PROC [dbo].[uspCreateTaxiAggregateTable] @TableName [NVARCHAR](500)
AS
BEGIN
    IF EXISTS (SELECT top 1 1 FROM sys.tables WHERE name=@TableName+'_AGG')
	BEGIN
		DECLARE @DropTbl NVARCHAR(4000) = N'DROP TABLE [dbo].['+@TableName+'_AGG]';
        EXEC sp_executesql @tsql = @DropTbl;
	END

    BEGIN
        DECLARE @CreateTbl NVARCHAR(4000) = N'CREATE TABLE [dbo].['+@TableName+'_AGG]
        WITH
        (
            DISTRIBUTION = ROUND_ROBIN
        )
        AS
          SELECT datepart(year,pickup_Datetime) as PickYear ,
                 datepart(month,pickup_Datetime) as PickMonth,
                 datepart(week,pickup_Datetime) as PickWeek,
                 vendor_id,
                 payment_type,
                 count(distinct(concat(pickup_Datetime,rate_Code_id))) as TotalTrips,
                 sum(trip_distance) as TotalDistance,
                 sum(fare_amount) as TotalFareAmount,
                 sum(total_amount) as TotalAmount
            FROM [dbo].['+@TableName+']
        GROUP BY datepart( year , pickup_Datetime),
                 datepart(month,pickup_Datetime),
                 datepart(week,pickup_Datetime),
                 vendor_id,
                 payment_type;';

        EXEC sp_executesql @tsql = @CreateTbl;
    END
END
GO