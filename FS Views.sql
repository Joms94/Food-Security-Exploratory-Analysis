-- Searches most recent food security data for specified string.

CREATE OR ALTER FUNCTION
	FindIndicators
	(@SearchString varchar(40))
RETURNS TABLE
AS
RETURN
	WITH rowtable AS (
		SELECT
			Area, 
			[Value] AS ValueName,
			[Year],
			(ROW_NUMBER() OVER(PARTITION BY Area
		   	ORDER BY [Year])) AS Row_No
		FROM [Food Security Database].[dbo].[FS_Indicators]
		WHERE Item LIKE @SearchString)
	SELECT
		ogrowtable.Area,
		ogrowtable.ValueName,
		ogrowtable.[Year] AS Last_Update,
		ogrowtable.Row_No
	FROM rowtable AS ogrowtable
	LEFT JOIN rowtable AS newrowtable -- Filters non-recent results.
		ON ogrowtable.Area = newrowtable.Area
		AND ogrowtable.Row_No < newrowtable.Row_No
	WHERE newrowtable.Row_No IS NULL;
GO


-- Searches for most recent form of agricultural, environmental or adjacent R&D spending.

CREATE OR ALTER FUNCTION
	FindSpending
	(@SearchString varchar(40))
RETURNS TABLE
AS
RETURN
	WITH spending AS (
		SELECT
			ge.Area,
			ge.Item,
			ge.[Value] AS MillionsUSD,
			ge.[Year] AS Last_Update,
			(ROW_NUMBER() OVER(PARTITION BY ge.Area
		   	ORDER BY ge.[Year] ASC)) AS Row_No
		FROM [Food Security Database].[dbo].[FS_Gov_Expenditure] AS ge
		WHERE ge.Item LIKE @SearchString)
	SELECT
		orig.Area,
		orig.MillionsUSD
	FROM spending AS orig
	LEFT JOIN spending AS new
		ON orig.Area = new.Area
		AND orig.Row_No < new.Row_No
	WHERE new.Row_No IS NULL;
GO


-- Percent of people using at least basic drinking water services.
-- Purpose of view: Useful heuristic for quickly gauging basic water access.

CREATE OR ALTER VIEW dbo.BasicWaterUse AS
SELECT
	Area,
	ValueName AS WaterUsePct,
	Last_Update,
	Row_No
FROM FindIndicators('%at least basic drinking%');
GO


-- Percent of people using at least basic sanitation services.
-- Purpose of view: Useful heuristic for quickly gauging sanitation access.

CREATE OR ALTER VIEW dbo.SanitationUse AS
SELECT
	Area,
	ValueName AS SanitationUsePct,
	Last_Update,
	Row_No
FROM FindIndicators('%basic sanitation%');
GO


-- Percent of people using basic clean drinking water facilities vs safely managed.
-- Purpose of view: It's important for long-term health to know which countries have achieved safe access standards. 
--		    

CREATE OR ALTER VIEW dbo.SafeWater AS
WITH WaterTable AS (
	SELECT
		Area,
		(CASE
			WHEN Item LIKE '%basic drinking water%'
			THEN [Value]
			END) as BasicWaterPct,
		(CASE
			WHEN Item LIKE '%safely managed drinking%'
			THEN [Value]
			END) as SafeWaterPct
	FROM [Food Security Database].[dbo].[FS_Indicators]
	WHERE Item LIKE ('%basic drinking water%')
		OR Item LIKE ('%safely managed drinking%'))
SELECT 
	WaterTable.Area,
	MAX(WaterTable.BasicWaterPct) as BasicWaterPct,
	MAX(WaterTable.SafeWaterPct) as SafeWaterPct
FROM WaterTable
GROUP BY WaterTable.Area;
GO


-- Prevalence of moderate to severe food insecurity (3-year average) by country.
-- Purpose of view: Useful for prioritising which countries are in greatest need.
-- Note: More information on this metric available in README. Null values excluded. Uses most recent data available to each country.

CREATE OR ALTER VIEW dbo.FoodSecurityAvg AS
SELECT
	Area,
	ValueName AS InsecurityPct,
	Last_Update,
	Row_No
FROM FindIndicators('%moderate or severe food insecurity%')
WHERE ValueName IS NOT NULL;
GO


-- Prevalence of severe food insecurity (3-year average) by country.
-- Purpose of view: As above.

CREATE OR ALTER VIEW dbo.SevereFoodSecurityAvg AS
SELECT
	Area,
	ValueName AS SevereInsecurityPct,
	Last_Update,
	Row_No
FROM FindIndicators('Prevalence of severe food%')
WHERE ValueName IS NOT NULL;
GO


-- Impact of political instability on food security.
-- Purpose of view: Determining the extent to which political instability influences food security could influence policy.

CREATE OR ALTER VIEW dbo.PoliticalInstability AS
SELECT
	Area,
	ValueName AS StabilityIndex,
	Last_Update,
	Row_No
FROM FindIndicators('Political stability%')
WHERE ValueName IS NOT NULL;
GO


-- General environmental protection spending by country (USD 2015).
-- Purpose of view: Point of comparison with food security metrics.

CREATE OR ALTER VIEW dbo.EnvProtection AS
SELECT
	Area,
	MillionsUSD AS EnvProtectionSpending
FROM FindSpending('Environmental protection (Ge%')
WHERE MillionsUSD IS NOT NULL;
GO


-- General agriculture, forestry and fisheries spending by country (USD 2015).
-- Purpose of view: Point of comparison with food security metrics.

CREATE OR ALTER VIEW dbo.AgriSpend AS
SELECT
	Area,
	MillionsUSD AS AgricultureSpending
FROM FindSpending('Agriculture, forestry, fishing (Gen%')
WHERE MillionsUSD IS NOT NULL;
GO
