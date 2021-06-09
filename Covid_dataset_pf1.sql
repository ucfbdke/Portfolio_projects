-- Explore dataset without continents
SELECT TOP(100) *
FROM Portfolio..Deaths$
WHERE continent IS NOT NULL
ORDER BY 3,4;

-- Explore continent dataset
SELECT *
FROM Portfolio..Deaths$
WHERE continent IS NULL
ORDER BY 3,4;

-- Temporal case data per country
SELECT location, date, new_cases, total_cases, ISNULL(total_deaths, 0) AS total_deaths, FORMAT([population], '###,###,###,###') AS population, ROUND((total_cases/population),4) AS case_ratio
FROM Portfolio..Deaths$
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Average non-NULL reproduction rate per country and R level classification.
SELECT location, population, AVG(CAST(reproduction_rate AS DEC)) AS Average_rep_rate,
CASE
WHEN(AVG(CAST(reproduction_rate AS DEC)) <= 0.8) THEN 'Low reproduction rate'
WHEN(AVG(CAST(reproduction_rate AS DEC)) BETWEEN 0.8 AND 1.05) THEN 'Medium reproduction rate'
ELSE 'High reproduction rate'
END AS R_level
FROM Portfolio..Deaths$
WHERE continent IS NOT NULL AND continent NOT IN('Africa', 'Asia')
GROUP BY location, population
HAVING AVG(CAST(reproduction_rate AS DEC)) IS NOT NULL
ORDER BY Average_rep_rate

-- When did the case ratio reach 10% if it did (per country)?
SELECT location, MIN(date) AS date, MIN((total_cases/population)) AS max_case_ratio
FROM Portfolio..Deaths$
WHERE continent IS NOT NULL
AND (total_cases/population) >= 0.1
GROUP BY location
ORDER BY date

-- Deaths per cases (%) in the USA
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
SELECT location, FORMAT([population], '###,###,###,###') AS population, MAX(CAST(total_deaths AS INT)) AS Max_deaths
FROM Portfolio..Deaths$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Max_deaths DESC;

-- Total deaths by continent
SELECT location, MAX(CAST(total_deaths AS INT)) AS Max_deaths
FROM Portfolio..Deaths$
WHERE continent IS NULL
AND location NOT LIKE 'World'
GROUP BY location
ORDER BY Max_deaths DESC;

-- New cases and new deaths globally
SELECT date, SUM(new_cases) AS new_cases, SUM(CAST(new_deaths AS INT)) AS new_deaths
FROM Portfolio..Deaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1;

-- Total population and vaccinations (cumulative count)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS Cumulative_count
FROM Portfolio..Deaths$ dea
JOIN Portfolio..Vaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date

-- Total population and vaccinations (cumulative percentage)
WITH Pop_Vac(continent, location, date, population, new_vaccinations, Cumulative_count) AS
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
DROP TABLE IF EXISTS #Percent_pop_vaccinated

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
DROP VIEW IF EXISTS Percent_pop_vaccinated;

CREATE VIEW Percent_pop_vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS Cumulative_count
FROM Portfolio..Deaths$ dea
JOIN Portfolio..Vaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT * FROM Percent_pop_vaccinated
ORDER BY location, date;
