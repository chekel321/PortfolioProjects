select *
from PortfolioProject..CovidDeaths
order by 3, 4

--select *
--from PortfolioProject..CovidVaccinations
--order by 3, 4

-----------------------------------------------------------------------------------------
-- Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2
-----------------------------------------------------------------------------------------

-- Looking at Total Cases vs Total Deaths in USA
-- Shows likely hood of dying if you contract Covid in your country

SELECT location, date, total_cases, CAST(total_deaths AS int) AS total_deaths,(CAST(total_deaths as int)/total_cases) *100 AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states'
ORDER BY 1,2

-----------------------------------------------------------------------------------------

-- Looking at Total Cases vs Population
-- Shows what percentage of the population got Covid

SELECT location, date, population, total_cases, (total_cases/population) *100 AS covid_contraction_percentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states'
ORDER BY 1, 2

-----------------------------------------------------------------------------------------

-- shows what percentage of the population got Covid as of Today
-- Ordered by country
--SELECT location, MAX(population) AS population, MAX(total_cases) AS total_cases, MAX((total_cases/population)) *100 AS covid_contraction_percentage
--FROM PortfolioProject..CovidDeaths
----WHERE location LIKE '%states'
--GROUP BY location
--order by 1, 2

-----------------------------------------------------------------------------------------
-- Looking at Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)) *100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY 4 DESC

-----------------------------------------------------------------------------------------

-- Showing counries with Highest Death Count per Population
-- Data type was incorrect for total_deaths, we need to convert total_deaths to int
SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

---------------------------------------------------------------------------------------------------
-- LET'S BREAK THINGS DOWN

-----------------------------------------------------------------------------------------

-- Showing continents with the highest death count per population
SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL AND location NOT IN ('World', 'Upper middle income', 'High income', 
'Lower middle income', 'Low income', 'International', 'European Union') 
GROUP BY location
ORDER BY TotalDeathCount DESC


--------------------------------------------------------------------------------------------

-- GLOBAL NUMBERS

-- new cases and new deaths by date
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, 
	SUM(CAST(new_deaths AS int))/SUM(new_cases) *100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL --AND new_cases IS NOT NULL
GROUP BY date
ORDER BY date

--Total new cases and deaths as of today
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, 
	SUM(CAST(new_deaths AS int))/SUM(new_cases) *100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL --AND new_cases IS NOT NULL
--GROUP BY date
--ORDER BY date


--------------------------------------------------------------------------------------------
-- JOIN CovidDeaths and CovidVaccinations Tables

SELECT TOP 10 *
FROM PortfolioProject..CovidDeaths AS CD
JOIN PortfolioProject..CovidVaccinations AS CV
	ON CD.location = CV.location 
	AND CD.date = CV.date

-- Looking at total Population vs Vaccinations

SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
, SUM(CAST(CV.new_vaccinations AS bigint)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS CD
JOIN PortfolioProject..CovidVaccinations AS CV
	ON CD.location = CV.location 
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
ORDER BY 2, 3

--------------------------------------------------------------------------------------------------------------------------------------
-- CTE is a temporary table named result set created from a simple SELECT statement that can be used in a subsequent SELECT statement who's results
--	are stored in a virtual table
-- Create CTE to query against it (similar to temporary table)
DROP TABLE IF EXISTS #PercentPopulationVaccinated 
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS(
SELECT CD.continent, CD.location, CD.date, CD.population, cv.new_vaccinations
, SUM(CONVERT(bigint,cv.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS CD
JOIN PortfolioProject..CovidVaccinations AS CV
	ON CD.location = CV.location
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentPopulationVaccinated
FROM PopvsVac

-- Temp Table
CREATE TABLE #PercentPopulationVaccinated
(
	Continent nvarchar(255), 
	Location nvarchar(255), 
	Date DATETIME, 
	Population numeric,
	New_Vaccinations numeric,
	RollingPeopleVaccinated numeric,
)
INSERT INTO #PercentPopulationVaccinated
SELECT CD.continent, CD.location, CD.date, CD.population, cv.new_vaccinations
, SUM(CONVERT(bigint,cv.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS CD
JOIN PortfolioProject..CovidVaccinations AS CV
	ON CD.location = CV.location
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated


-- Create View to store data for late visualizations

-- This table shows the amount of new vaccinations per day and sums up the total amount of people that are vaccinated.
GO
CREATE VIEW PercentPopulationVaccinated AS
SELECT CD.continent, CD.location, CD.date, CD.population, cv.new_vaccinations
, SUM(CONVERT(bigint,cv.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS CD
JOIN PortfolioProject..CovidVaccinations AS CV
	ON CD.location = CV.location
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL