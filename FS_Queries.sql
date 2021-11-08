-- SECTION 1: Water & Sanitation
-- Drinking water and sanitation are key food security indicators. 
-- This section will briefly explore their relationship with respect to various forms of agricultural, R&D and environmental protection spending.


-- Which countries have the least people using at least basic clean drinking water services?
-- Purpose of query: Useful for prioritising which countries are most in need of water infrastructure.

SELECT *
FROM BasicWaterUse
ORDER BY WaterUsePct ASC;


--Water access vs expenditure.
--Compares percent of people with access to basic clean water services against total government environmental protection spending (both state and federal).
--Purpose of query: Knowing if environmental protection spending influences basic water access could influence policy.

WITH comparison AS (
	SELECT
		bwu.Area,
		bwu.WaterUsePct,
		ge.[Value] AS EnvExpenditureMillionsUSD,
		(ROW_NUMBER() OVER(PARTITION BY bwu.Area
						   ORDER BY bwu.Last_Update)) AS Row_No
	FROM BasicWaterUse AS bwu
	INNER JOIN [Food Security Database].[dbo].[FS_Gov_Expenditure] AS ge
		ON bwu.Area = ge.Area
	WHERE ge.Item LIKE 'Environmental protection (Gen%')
SELECT
	c.Area,
	c.WaterUsePct,
	c.EnvExpenditureMillionsUSD
FROM comparison AS c
LEFT JOIN comparison AS newc -- Filters non-recent results.
	ON c.Area = newc.Area
	AND c.Row_No < newc.Row_No
WHERE newc.Row_No IS NULL
ORDER BY c.WaterUsePct ASC;



-- Which countries have the least people using at least basic sanitation services?
-- Purpose of query: Useful for prioritising which countries are most in need of sanitation services.

SELECT *
FROM SanitationUse
ORDER BY SanitationUsePct;


-- Sanitation access vs expenditure
-- Compares access to sanitation against environmental protection expenditure.
-- Purpose of query: Could have an influence on sanitation and therefore warrant further analysis
--		     (eg low environmental protection spending -> env degradation -> poor conditions). 

WITH comparison AS (
	SELECT
		su.Area,
		su.SanitationUsePct,
		ge.[Value] AS EnvExpenditureMillionsUSD,
		(ROW_NUMBER() OVER(PARTITION BY su.Area
						   ORDER BY su.Last_Update)) AS Row_No
	FROM SanitationUse AS su
	INNER JOIN [Food Security Database].[dbo].[FS_Gov_Expenditure] AS ge
		ON su.Area = ge.Area
	WHERE ge.Item LIKE 'Environmental protection (Gen%')
SELECT
	c.Area,
	c.SanitationUsePct,
	c.EnvExpenditureMillionsUSD
FROM comparison AS c
LEFT JOIN comparison AS newc -- Filters non-recent results.
	ON c.Area = newc.Area
	AND c.Row_No < newc.Row_No
WHERE newc.Row_No IS NULL
ORDER BY c.SanitationUsePct ASC;


-- Sanitation vs clean water access.
-- Compares percent of population using basic sanitation against percent using at least basic drinking water services.
-- Purpose of query: Challenging an assumption that countries with poor sanitation must also have a similar number of poor water facilities, and vice versa.

SELECT
	bwu.Area,
	su.SanitationUsePct,
	bwu.WaterUsePct
FROM
	BasicWaterUse as bwu
INNER JOIN SanitationUse as su
	ON bwu.Area = su.Area
ORDER BY bwu.WaterUsePct;


-- How many countries have greater access to sanitation than clean water services, and to what extent?
-- Compares percent of people using sanitation services against those using at least basic water services.
-- Purpose of query: If significantly more people have access to sanitation than basic drinking water services,
--		     this implies a serious, perhaps dangerous, quality of water used in sanitation, if any at all.
--		     This would be worthy of additional research.

SELECT
	bwu.Area,
	su.SanitationUsePct,
	bwu.WaterUsePct
FROM
	BasicWaterUse as bwu
INNER JOIN SanitationUse as su
	ON bwu.Area = su.Area
WHERE su.SanitationUsePct > bwu.WaterUsePct
ORDER BY bwu.WaterUsePct;


-- Basic water access vs safely managed.
-- Compares percent of population with access to basic drinking water against those able to access safely managed alternatives.
-- Note: This query exlcudes countries who haven't disclosed the percentage of their population with access to safely managed drinking water.
-- Purpose of query: It's important for long-term health to know which countries have achieved reasonble safe access standards.

SELECT *
FROM SafeWater
WHERE SafeWaterPct IS NOT NULL
ORDER BY SafeWaterPct;


-- Percent of available drinking water services that are safely managed.
-- Purpose of query: As above.

SELECT
	Area,
	(ROUND((SafeWaterPct/BasicWaterPct) * 100, 2)) AS PctSafelyManaged
FROM SafeWater
WHERE SafeWaterPct IS NOT NULL
ORDER BY PctSafelyManaged;


-- Percent of available drinking water services that are safely managed vs government environmental protection spending (in millions USD).
-- Excludes countries that haven't disclosed either this spending or their safely managed water facilities.
-- Note: Given this isn't a per capita calculation, smaller countries are at an advantage.
-- Purpose of query: Learning if there's a connection between environmental protection spending and safe water access could be cause for further research.

WITH PercentSafe AS
	(SELECT
		Area,
		(ROUND((SafeWaterPct/BasicWaterPct) * 100, 2)) as PctSafelyManaged
	 FROM SafeWater
	 WHERE SafeWaterPct IS NOT NULL)
SELECT 
	PercentSafe.Area,
	PercentSafe.PctSafelyManaged AS PctSafelyManaged,
	ROUND(ge.[Value], 2) AS MillionsUSD
FROM PercentSafe
INNER JOIN [Food Security Database].[dbo].[FS_Gov_Expenditure] AS ge
	ON PercentSafe.Area = ge.Area
WHERE ge.Item LIKE '%Environmental protection (Cent%'
AND ge.[Year] IN (SELECT MAX([Year])
		  FROM [Food Security Database].[dbo].[FS_Gov_Expenditure] AS ge
		  INNER JOIN PercentSafe AS ps
			ON ge.Area = ps.Area)
ORDER BY PctSafelyManaged ASC;


-- SECTION 2: Food & Political Stability
-- This section will briefly explore food security in relation to a variety of factors.


-- Prevalence of moderate to severe food insecurity (3-year average) by country.
-- Purpose of query: Useful for prioritising which countries are in greatest need.
-- Note: More information on this metric available in README. Null values excluded. Uses most recent data available to each country.

SELECT
	Area,
	InsecurityPct
FROM FoodSecurityAvg
ORDER BY InsecurityPct DESC;


-- Impact of political instability on food security.
-- Purpose of query: Determining the extent to which political instability influences food security could inform policy.
-- Note: Negative stability indicates a threat to democracy, with -2 or lower indicating severe threat, such as an ongoing war or significant terrorist activity.

SELECT
	fsa.Area,
	fsa.InsecurityPct AS FoodInsecurityPct,
	pin.StabilityIndex
FROM dbo.FoodSecurityAvg AS fsa
INNER JOIN dbo.PoliticalInstability AS pin
	ON pin.Area = fsa.Area
ORDER BY FoodInsecurityPct DESC;


-- Moderate food insecurity % in the total population vs severe.
-- Purpose of query: It's useful for the purpose of humanitarian triage to know 
--		     which countries have the higher proportion of severe food insecurity vs moderate.
-- Note: PctOfTotalSevere shows the percent of a country's total insecurity that is severe.

WITH sfi AS (
	SELECT
		Area,
		Item,
		[Value] AS InsecurityPct,
		(ROW_NUMBER() OVER(PARTITION BY Area
		ORDER BY [Year] ASC)) AS Row_No -- Used to track most recent update to data.
	FROM [Food Security Database].[dbo].[FS_Indicators]
	WHERE Item LIKE 'Prevalence of severe food%')
SELECT
	sfi.Area,
	(fsa.InsecurityPct-sfi.InsecurityPct) AS ModerateInsecurityPct,
	sfi.InsecurityPct AS SevereInsecurityPct,
	fsa.InsecurityPct AS TotalInsecurityPct,
	ROUND(((sfi.InsecurityPct/fsa.InsecurityPct) * 100), 2) AS PctOfTotalSevere
FROM sfi
INNER JOIN dbo.FoodSecurityAvg AS fsa
	ON sfi.Area = fsa.Area
WHERE sfi.Row_No = 2
AND sfi.InsecurityPct <= 100
ORDER BY PctOfTotalSevere DESC;


-- Does food insecurity decrease with agriculture spending?
-- Purpose of query: Critical knowledge for organisations or governments seeking to improve food security.
-- Note: 'InsecurityPct' refers to percent of the population suffering from moderate or severe food insecurity. 
--	 'MillionsUSD' refers to state and federal government agriculture, fisheries and forestry spending combined in 2015 USD.

WITH spending AS (
	SELECT
		ge.Area,
		ge.Item,
		ge.[Value] AS MillionsUSD,
		ge.[Year] AS Last_Update,
		(ROW_NUMBER() OVER(PARTITION BY ge.Area
	   	ORDER BY ge.[Year] ASC)) AS Row_No
	FROM [Food Security Database].[dbo].[FS_Gov_Expenditure] AS ge
	WHERE ge.Item LIKE 'Agriculture, forestry, fishing (Gen%')
SELECT
	orig.Area,
	fsa.InsecurityPct,
	ROUND(orig.MillionsUSD, 2) AS MillionsUSD,
	orig.Last_Update
FROM spending AS orig
LEFT JOIN spending AS new
	ON orig.Area = new.Area
	AND orig.Row_No < new.Row_No -- Leaves only the most recent data in selection.
INNER JOIN FoodSecurityAvg AS fsa
	ON orig.Area = fsa.Area
WHERE new.Row_No IS NULL
AND fsa.InsecurityPct IS NOT NULL
ORDER BY MillionsUSD DESC;


-- All data together.
-- Purpose of query: Easier visualisation later (Tableau Public can't connect to SQL and I'm not a rich man!).

SELECT
	sw.Area,
	sw.BasicWaterPct AS BasicWaterAccess,
	sw.SafeWaterPct AS SafeWaterAccess,
	(ROUND((sw.SafeWaterPct/sw.BasicWaterPct) * 100, 2)) AS PctWaterSafe,
	su.SanitationUsePct AS SanitationAccess,
	(fsa.InsecurityPct - sfsa.SevereInsecurityPct) AS ModerateFoodInsecurityPct,
	sfsa.SevereInsecurityPct AS SevereFoodInsecurityPct,
	fsa.InsecurityPct AS TotalFoodInsecurityPct,
	(ROUND((sfsa.SevereInsecurityPct / fsa.InsecurityPct) * 100, 2)) AS PctFoodInsecuritySevere,
	ep.EnvProtectionSpending,
	agri.AgricultureSpending
FROM SafeWater AS sw
LEFT JOIN SanitationUse AS su
	ON sw.Area = su.Area
LEFT JOIN FoodSecurityAvg AS fsa
	ON sw.Area = fsa.Area
LEFT JOIN PoliticalInstability AS ins
	ON sw.Area = ins.Area
LEFT JOIN EnvProtection AS ep
	ON sw.Area = ep.Area
LEFT JOIN AgriSpend AS agri
	ON sw.Area = agri.Area
LEFT JOIN SevereFoodSecurityAvg AS sfsa
	ON sw.Area = sfsa.Area
ORDER BY TotalFoodInsecurityPct DESC;
