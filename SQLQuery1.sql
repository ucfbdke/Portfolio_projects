SELECT * 
FROM Portfolio..Deaths$
WHERE continent IS NOT NULL
ORDER BY 3,4;

SELECT location, date, total_cases, new_cases, ISNULL(total_deaths, 0) AS total_deaths, FORMAT([population], '###,###,###,###') AS population
FROM Portfolio..Deaths$
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Total cases vs total deaths in the USA
SELECT location, date, FORMAT([total_cases], '###,###,###,###') AS Total_cases, total_deaths, ROUND((total_deaths/total_cases)*100, 2) AS Death_percentage
FROM Portfolio..Deaths$
WHERE location like '%states%'
ORDER BY 1,2;

-- Total cases vs population in Hungary
SELECT location, date, FORMAT([total_cases], '###,###,###,###') as Total_cases, FORMAT([population], '###,###,###,###,###') AS Population, ROUND((total_cases/population)*100, 4) AS Case_percentage
FROM Portfolio..Deaths$
WHERE location = 'Hungary'
ORDER BY 1,2;

-- Highest infection rates per country
SELECT location, population, MAX(total_cases) AS Highest_inf, ROUND((MAX(total_cases)/population)*100, 4) AS Max_case_percentage
FROM Portfolio..Deaths$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC;

-- Total deaths
-- total_deaths is VAR type therefore order is not right, need to convert to integer.
SELECT location, FORMAT([population], '###,###,###,###') AS population, MAX(CAST(total_deaths AS INT)) AS Max_deaths
FROM Portfolio..Deaths$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Max_deaths DESC;

-- Total deaths by continent
SELECT location, MAX(CAST(total_deaths AS INT)) AS Max_deaths
FROM Portfolio..Deaths$
WHERE continent IS NULL
GROUP BY location
ORDER BY Max_deaths DESC;

-- Global numbers
SELECT date, SUM(new_cases) AS new_cases, SUM(CAST(new_deaths AS INT)) AS new_deaths
FROM Portfolio..Deaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1;

-- Total population and vaccinations
-- Use CTE ~ Common Table Expression
WITH Pop_Vac (continent, location, date, population, new_vaccinations, Cumulative_count) AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS Cumulative_count
FROM Portfolio..Deaths$ dea
JOIN Portfolio..Vaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL)

SELECT *, (Cumulative_count/population)*100 AS Vac_pop_percentage
FROM Pop_Vac
ORDER BY 2,3

-- Create table
DROP TABLE IF EXISTS #Percent_pop_vaccinated -- Helps with alterations

CREATE TABLE #Percent_pop_vaccinated(
continent NVARCHAR(150),
location NVARCHAR(150),
date DATETIME,
population NUMERIC,
new_vaccinations NUMERIC,
cumulative_percentage NUMERIC)

INSERT INTO #Percent_pop_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS Cumulative_count
FROM Portfolio..Deaths$ dea
JOIN Portfolio..Vaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (cumulative_percentage/population)*100 AS Vac_pop_percentage
FROM #Percent_pop_vaccinated
ORDER BY 2,3

-- Create a view
CREATE VIEW Percent_pop_vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS Cumulative_count
FROM Portfolio..Deaths$ dea
JOIN Portfolio..Vaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT * FROM Percent_pop_vaccinated