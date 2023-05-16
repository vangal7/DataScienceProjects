SELECT *
FROM CovidPortfolioProject.dbo.CovidDeaths
ORDER BY continent, date


SELECT *
FROM CovidPortfolioProject.dbo.CovidVaccinations
ORDER BY location, date


--Select data to be used

SELECT location, date, population, total_cases, total_deaths
FROM CovidPortfolioProject.dbo.CovidDeaths
ORDER BY location, date

--Total Cases Per Million vs Total Deaths Per Million

-- Shows likelihood of dying from COVID per Country

SELECT location, date, total_cases, total_deaths, (cast(total_deaths as float)/total_cases)*100 as DeathPercentage
FROM CovidPortfolioProject.dbo.CovidDeaths
ORDER BY location, date


--Shows likelihood of dying from COVID in the US
SELECT location, date, total_cases, total_deaths, (cast(total_deaths as float)/total_cases)*100 as DeathPercentage
FROM CovidPortfolioProject.dbo.CovidDeaths
WHERE location like '%states'
ORDER BY location, date


--Total Cases vs Population in the US: Shows what percentage of population got COVID

SELECT location, date,  population, total_cases, ((cast(total_cases as float))/population)*100 as PercentageWithCovid
FROM CovidPortfolioProject.dbo.CovidDeaths
WHERE location like '%states'
ORDER BY location, date


--Countries with Highest Infection Rate compared to Population

SELECT location,  population, MAX(total_cases) as HighestInfectionCount, Max((cast(total_cases as float))/population)*100 as PercentageWithCovid
FROM CovidPortfolioProject.dbo.CovidDeaths
GROUP BY location, population
ORDER BY PercentageWithCovid desc


--Countries with Highest Death Count per Population

SELECT location,  population, MAX(total_deaths) as TotalDeathCount, Max((cast(total_deaths as float))/population)*100 as DeathPerPopulation
FROM CovidPortfolioProject.dbo.CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY DeathPerPopulation desc


--Breaking it down by Continent...

--Showing continents with highest death count

SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM CovidPortfolioProject.dbo.CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc


--Global numbers

SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(cast(new_deaths AS float))/SUM(new_cases)*100 as DeathPercentage
FROM CovidPortfolioProject.dbo.CovidDeaths
WHERE continent is not null
ORDER BY  total_cases


--Looking at Total Population vs Vaccinations

--Using CTE

WITH PopvsVac(Continent, Location, Date, Population, NewVaccinations, RollingVaccinatedCount)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	as RollingVaccinatedCount
FROM CovidPortfolioProject.dbo.CovidDeaths dea
JOIN CovidPortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

)
SELECT *, cast(RollingVaccinatedCount as float)/Population*100 as PercentageVaccinated
FROM PopvsVac
ORDER BY location, date


--Using TEMP TABLE

DROP TABLE IF EXISTS #PercentVaccinated

CREATE TABLE #PercentVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population bigint,
New_Vaccinations bigint,
RollingVaccinatedCount bigint
)

INSERT INTO #PercentVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	as RollingVaccinatedCount
FROM CovidPortfolioProject.dbo.CovidDeaths dea
JOIN CovidPortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY location, date

SELECT *, Cast(RollingVaccinatedCount as float)/Population*100 as PercentVaccinated
FROM #PercentVaccinated
ORDER BY location, date


--CREATING VIEW to store data for later visulations

CREATE VIEW PercentVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	as RollingVaccinatedCount
FROM CovidPortfolioProject.dbo.CovidDeaths dea
JOIN CovidPortfolioProject.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT *
FROM PercentVaccinated
