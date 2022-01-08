SELECT *
FROM SQLProject1..covid_deaths
ORDER BY 3,4



--SELECT *
--FROM SQLProject1..covid_vaccinations
--ORDER BY 3,4



SELECT location, date, total_cases, new_cases, total_deaths, population
FROM SQLProject1..covid_deaths
ORDER BY 1,2



-- Total cases vs total deaths
-- Indicates COVID-19 fatality rates in Canada

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM SQLProject1..covid_deaths
WHERE location LIKE '%CANADA%'
ORDER BY 1,2


-- Total cases vs population
-- Percentage of population infected with COVID-19

SELECT location, date, population, total_cases, (total_cases/population)*100 AS percent_population_infected
FROM SQLProject1..covid_deaths
--WHERE location LIKE '%CANADA%'
ORDER BY 1,2



-- Countries with highest infection rates compared to their population

SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS percent_population_infected
FROM SQLProject1..covid_deaths
--WHERE location LIKE '%CANADA%'
GROUP BY location, population
ORDER BY percent_population_infected DESC



-- Countries with highest death count per population

SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM SQLProject1..covid_deaths
--WHERE location LIKE '%CANADA%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC



-- Continents with highest death count per population

SELECT continent, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM SQLProject1..covid_deaths
--WHERE location LIKE '%CANADA%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC



-- Global figures by date

SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS deaths_percentage
FROM SQLProject1..covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2



-- Total numbers

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS deaths_percentage
FROM SQLProject1..covid_deaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2



-- Joining the 2 tables

SELECT *
FROM SQLProject1..covid_deaths dea
JOIN SQLProject1..covid_vaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date



-- Total population vs vaccinations
-- Shows percentage of population that has recieved at least one vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM SQLProject1..covid_deaths dea
JOIN SQLProject1..covid_vaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2,3



-- Using CTE to perform calculations on partition in previous query

WITH POPVSVAC (continent, location, date, population, new_vaccinations, rolling_vaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS rolling_vaccinations --, (rolling_vaccinations/population)*100
FROM SQLProject1..covid_deaths dea
JOIN SQLProject1..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (rolling_vaccinations/population)*100
FROM POPVSVAC



-- Using temp table to perform calculations on partition in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS rolling_vaccinations
--, (rolling_vaccinations/population)*100
FROM SQLProject1..covid_deaths dea
JOIN SQLProject1..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated



-- Creating view to store data

CREATE VIEW PercentPopulationVaccinated
AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
--, (rolling_vaccinations/population)*100
FROM SQLProject1..covid_deaths dea
JOIN SQLProject1..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
