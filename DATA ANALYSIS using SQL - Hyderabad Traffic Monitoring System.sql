-- Create a new database for traffic monitoring
CREATE DATABASE TRAFFIC_MONITORING_SYSTEM;

-- Switch to the newly created database
USE TRAFFIC_MONITORING_SYSTEM;

/* Data Import: Data was imported into the table [Hyderabad Traffic Monitoring System_Updated]
   using SQL Server Management Studio's Import functionality. */

-- Select all columns from the imported table to view the data
SELECT * 
FROM [dbo].[Hyderabad Traffic Monitoring System_Updated];


-- LET'S GET STARTED WITH EXPLORATORY DATA ANALYSIS USING SQL


-- Let's write a SQL procedure to analyze time-series data for traffic prediction.

GO
CREATE PROCEDURE AnalyzeTrafficData
    @Area NVARCHAR(255),
    @Location NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF OBJECT_ID('tempdb..#TrafficSummary') IS NOT NULL
            DROP TABLE #TrafficSummary;

        CREATE TABLE #TrafficSummary (
            [Date] DATE,
            [Hour] INT,
            AverageVehicleCount FLOAT,
            AverageSpeed FLOAT
        );

        INSERT INTO #TrafficSummary ([Date], [Hour], AverageVehicleCount, AverageSpeed)
        SELECT 
            [Date],
            DATEPART(HOUR, [Timestamp]) AS [Hour],  -- Assuming the column is [Timestamp]
            AVG(CAST([Vehicle Count] AS FLOAT)) AS AverageVehicleCount,
            AVG([Average Speed (in km/h)]) AS AverageSpeed
        FROM [dbo].[Hyderabad Traffic Monitoring System_Updated]
        WHERE [Area] = @Area
          AND [Location] = @Location
        GROUP BY [Date], DATEPART(HOUR, [Timestamp]);

        WITH PeakHourData AS (
            SELECT 
                [Date],
                [Hour],
                AVG(AverageVehicleCount) AS AvgVehicleCount
            FROM #TrafficSummary
            GROUP BY [Date], [Hour]
        ),
        MaxPeakHour AS (
            SELECT 
                [Date],
                MAX(AvgVehicleCount) AS MaxAvgVehicleCount
            FROM PeakHourData
            GROUP BY [Date]
        )
        SELECT 
            p.[Date],
            p.[Hour] AS PeakHour,
            MAX(t.AverageVehicleCount) AS MaxVehicleCount,
            AVG(t.AverageVehicleCount) AS AvgVehicleCount,
            MAX(t.AverageSpeed) AS MaxSpeed,
            AVG(t.AverageSpeed) AS AvgSpeed
        FROM #TrafficSummary AS t
        JOIN PeakHourData AS p
            ON t.[Date] = p.[Date] AND t.[Hour] = p.[Hour]
        JOIN MaxPeakHour AS m
            ON t.[Date] = m.[Date] AND p.AvgVehicleCount = m.MaxAvgVehicleCount
        GROUP BY p.[Date], p.[Hour]
        ORDER BY p.[Date], MaxVehicleCount DESC;

    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_SEVERITY() AS ErrorSeverity,
            ERROR_STATE() AS ErrorState,
            ERROR_PROCEDURE() AS ErrorProcedure,
            ERROR_LINE() AS ErrorLine,
            ERROR_MESSAGE() AS ErrorMessage;
    END CATCH;

    IF OBJECT_ID('tempdb..#TrafficSummary') IS NOT NULL
        DROP TABLE #TrafficSummary;
END;
GO

-- Test Cases For The Procedure

EXEC AnalyzeTrafficData 
    @Area = 'Madhapur', 
    @Location = 'B';

EXEC AnalyzeTrafficData 
    @Area = 'Gachibowli', 
    @Location = 'D';


-- Let's develop SQL queries to further our analysis by extracting specific information from the dataset.

--Analysis: Average Speed by Location
--Description: Compute the average speed recorded at different locations, formatted to 2 decimal places.

SELECT 
    Location, 
    CAST(AVG([Average Speed (in km/h)]) AS DECIMAL(10, 2)) AS 'Average Speed'
FROM 
    [dbo].[Hyderabad Traffic Monitoring System_Updated]
GROUP BY 
    Location
ORDER BY 
    'Average Speed' DESC;


--Analysis: Average Vehicle Count by Area
--Description: Calculate the average number of vehicles for each area, formatted to 2 decimal places.

SELECT 
    Area, 
    CAST(AVG(CAST([Vehicle Count] AS FLOAT)) AS DECIMAL(10, 2)) AS 'Average Vehicle Count'
FROM 
    [dbo].[Hyderabad Traffic Monitoring System_Updated]
GROUP BY 
    Area
ORDER BY 
    'Average Vehicle Count' DESC;


--Analysis: Frequency of Extreme Congestion Levels by Date
--Description: Count how often high congestion levels (e.g., "High") are recorded for each date.

SELECT 
    [Date], 
    COUNT(*) AS 'Extreme Congestion Frequency'
FROM 
    [dbo].[Hyderabad Traffic Monitoring System_Updated]
WHERE 
    [Congestion Level] = 'Extreme'
GROUP BY 
    [Date]
ORDER BY 
    [Date];


--Analysis: Daily Traffic Trends
--Description: Determine the average vehicle counts and speeds for each day.

SELECT 
    [Date],
    CAST(AVG(CAST([Vehicle Count] AS FLOAT)) AS DECIMAL(10, 2)) AS 'Average Vehicle Count',
    CAST(AVG([Average Speed (in km/h)]) AS DECIMAL(10, 2)) AS 'Average Speed'
FROM 
    [dbo].[Hyderabad Traffic Monitoring System_Updated]
GROUP BY 
    [Date]
ORDER BY 
    [Date];


--Analysis: Impact of Weather Conditions on Traffic
--Description: Examine how different weather conditions affect vehicle counts and speeds.

SELECT 
    [Weather Condition],
    CAST(AVG(CAST([Vehicle Count] AS FLOAT)) AS DECIMAL(10, 2)) AS [Average Vehicle Count],
    CAST(AVG([Average Speed (in km/h)]) AS DECIMAL(10, 2)) AS [Average Speed]
FROM 
    [dbo].[Hyderabad Traffic Monitoring System_Updated]
GROUP BY 
    [Weather Condition]
ORDER BY 
    [Weather Condition];


--Analysis: Visibility’s Effect on Traffic
--Description: Analyze how visibility levels impact average vehicle count and speed.

SELECT 
    [Visibility Level],
    CAST(AVG(CAST([Vehicle Count] AS FLOAT)) AS DECIMAL(10, 2)) AS [Average Vehicle Count],
    CAST(AVG([Average Speed (in km/h)]) AS DECIMAL(10, 2)) AS [Average Speed]
FROM 
    [dbo].[Hyderabad Traffic Monitoring System_Updated]
GROUP BY 
    [Visibility Level]
ORDER BY 
    [Visibility Level];


--Analysis: Temperature and Traffic Correlation
--Description: Study the correlation between temperature and traffic metrics such as vehicle count and speed.

SELECT 
    CAST([Temperature (in C)] AS DECIMAL(10, 2)) AS [Temperature (C)],
    CAST(AVG(CAST([Vehicle Count] AS FLOAT)) AS DECIMAL(10, 2)) AS [Average Vehicle Count],
    CAST(AVG([Average Speed (in km/h)]) AS DECIMAL(10, 2)) AS [Average Speed]
FROM 
    [dbo].[Hyderabad Traffic Monitoring System_Updated]
GROUP BY 
    [Temperature (in C)]
ORDER BY 
    [Temperature (C)];


--Analysis: Humidity’s Influence on Traffic
--Description: Assess how humidity levels affect traffic patterns, including vehicle count and speed.

SELECT 
    CAST([Humidity (in %)] AS DECIMAL(10, 2)) AS [Humidity (%)],
    CAST(AVG(CAST([Vehicle Count] AS FLOAT)) AS DECIMAL(10, 2)) AS [Average Vehicle Count],
    CAST(AVG([Average Speed (in km/h)]) AS DECIMAL(10, 2)) AS [Average Speed]
FROM 
    [dbo].[Hyderabad Traffic Monitoring System_Updated]
GROUP BY 
    [Humidity (in %)]
ORDER BY 
    [Humidity (%)];


--Analysis: Wind Speed and Traffic Analysis
--Description: Evaluate the effect of wind speed on vehicle count and average speed.

SELECT 
    CAST([Wind Speed (in km/h)] AS DECIMAL(10, 2)) AS [Wind Speed (km/h)],
    CAST(AVG(CAST([Vehicle Count] AS FLOAT)) AS DECIMAL(10, 2)) AS [Average Vehicle Count],
    CAST(AVG([Average Speed (in km/h)]) AS DECIMAL(10, 2)) AS [Average Speed]
FROM 
    [dbo].[Hyderabad Traffic Monitoring System_Updated]
GROUP BY 
    [Wind Speed (in km/h)]
ORDER BY 
    [Wind Speed (km/h)];


--Analysis: Traffic Signal Status Impact
--Description: Investigate how different traffic signal statuses affect vehicle count and congestion levels.

SELECT 
    [Traffic Signal Status],
    CAST(AVG(CAST([Vehicle Count] AS FLOAT)) AS DECIMAL(10, 2)) AS [Average Vehicle Count],
    CAST(AVG([Average Speed (in km/h)]) AS DECIMAL(10, 2)) AS [Average Speed]
FROM 
    [dbo].[Hyderabad Traffic Monitoring System_Updated]
GROUP BY 
    [Traffic Signal Status]
ORDER BY 
    [Traffic Signal Status];


--Analysis: Roadwork and Traffic Flow
--Description: Analyze the impact of roadwork on traffic metrics like vehicle count and congestion.

SELECT 
    [Roadwork],
    CAST(AVG(CAST([Vehicle Count] AS FLOAT)) AS DECIMAL(10, 2)) AS [Average Vehicle Count],
    CAST(AVG([Average Speed (in km/h)]) AS DECIMAL(10, 2)) AS [Average Speed]
FROM 
    [dbo].[Hyderabad Traffic Monitoring System_Updated]
GROUP BY 
    [Roadwork]
ORDER BY 
    [Roadwork];


--Analysis: Accident Levels and Traffic
--Description: Examine how accident levels affect vehicle count, congestion, and average speed.

SELECT 
    [Accident Level],
    CAST(AVG(CAST([Vehicle Count] AS FLOAT)) AS DECIMAL(10, 2)) AS [Average Vehicle Count],
    CAST(AVG([Average Speed (in km/h)]) AS DECIMAL(10, 2)) AS [Average Speed]
FROM 
    [dbo].[Hyderabad Traffic Monitoring System_Updated]
GROUP BY 
    [Accident Level]
ORDER BY 
    [Accident Level];


--Analysis: Traffic Comparison by Area and Location
--Description: Compare traffic metrics such as vehicle count and speed across different areas and locations.

SELECT 
    [Area],
    [Location],
    CAST(AVG(CAST([Vehicle Count] AS FLOAT)) AS DECIMAL(10, 2)) AS [Average Vehicle Count],
    CAST(AVG([Average Speed (in km/h)]) AS DECIMAL(10, 2)) AS [Average Speed]
FROM 
    [dbo].[Hyderabad Traffic Monitoring System_Updated]
GROUP BY 
    [Area], [Location]
ORDER BY 
    [Area], [Location];


--Analysis: Average Traffic Metrics During Peak Hours by Day
--Description: Calculate average vehicle count and speed specifically during peak hours for each day.

WITH PeakHoursCTE AS (
    SELECT 
        [Date],
        DATEPART(HOUR, [Time]) AS PeakHour,
        AVG(CAST([Vehicle Count] AS FLOAT)) AS AvgVehicleCount
    FROM 
        [dbo].[Hyderabad Traffic Monitoring System_Updated]
    GROUP BY 
        [Date], DATEPART(HOUR, [Time])
),
DailyPeakHours AS (
    SELECT 
        [Date],
        PeakHour
    FROM 
        PeakHoursCTE
    WHERE 
        AvgVehicleCount = (
            SELECT MAX(AvgVehicleCount)
            FROM PeakHoursCTE AS Sub
            WHERE Sub.[Date] = PeakHoursCTE.[Date]
        )
)
SELECT 
    [Date],
    CAST(AVG(CAST([Vehicle Count] AS FLOAT)) AS DECIMAL(10, 2)) AS [Average Vehicle Count],
    CAST(AVG([Average Speed (in km/h)]) AS DECIMAL(10, 2)) AS [Average Speed]
FROM 
    [dbo].[Hyderabad Traffic Monitoring System_Updated]
WHERE 
    DATEPART(HOUR, [Time]) IN (
        SELECT PeakHour
        FROM DailyPeakHours
        WHERE [Date] = [dbo].[Hyderabad Traffic Monitoring System_Updated].[Date]
    )
GROUP BY 
    [Date]
ORDER BY 
    [Date];


--Analysis: Comparison of Traffic Metrics Before and After Roadwork
--Description: Analyze changes in traffic metrics before and after roadwork events.

SELECT 
    CASE 
        WHEN [Roadwork] = 'Yes' THEN 'During Roadwork'
        ELSE 'Before Roadwork'
    END AS [Roadwork Period],
    CAST(AVG(CAST([Vehicle Count] AS FLOAT)) AS DECIMAL(10, 2)) AS [Average Vehicle Count],
    CAST(AVG([Average Speed (in km/h)]) AS DECIMAL(10, 2)) AS [Average Speed]
FROM 
    [dbo].[Hyderabad Traffic Monitoring System_Updated]
GROUP BY 
    [Roadwork]
ORDER BY 
    [Roadwork Period];