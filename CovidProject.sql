select *
from PortfolioDatabase.dbo.CovidVaccinations
order by 3,4

select *
from PortfolioDatabase.dbo.CovidDeaths
order by 3,4


select location, date, total_cases, new_cases, total_deaths, population
from PortfolioDatabase.dbo.CovidDeaths
order by 1, 2


-- Looking at Total Cases vs. Total Deaths
--Shows Likelihood of dying if you contract Covid in your country

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioDatabase.dbo.CovidDeaths
where location like '%states%'
order by 1, 2

--Looking at Total Cases vs Population
--Shows percent of population got Covid

select location, date, population, total_cases, (total_cases/population)*100 as DeathPercentage
from PortfolioDatabase.dbo.CovidDeaths
where continent IS NOT NULL
order by 1, 2

--Looking at countries with highest infection rate compared to pop.
--Results from this one are alarming. Seems like there must be an incentive to find cases in some of these countries. Top ten between 60 and 75%

select location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
from PortfolioDatabase.dbo.CovidDeaths
where continent IS NOT NULL
Group By location, population
order by PercentPopulationInfected Desc

--Showing Countries with highest Death Count Per Population
-- They have strange info in the "location" column. There are locations that aren't countries but income groups or continents.

select location, MAX(Total_Deaths) as TotalDeathCount
from PortfolioDatabase.dbo.CovidDeaths
where continent IS NOT NULL
Group By location
order by TotalDeathCount Desc

--let's break things down by continent
--showing death count by continent
--I just ran the last query and this one together and the numbers for US and NA are exactly the same so there are no numbers from Canada?

select continent, MAX(Total_Deaths) as TotalDeathCount
from PortfolioDatabase.dbo.CovidDeaths
where continent IS NOT NULL
Group By continent
order by TotalDeathCount Desc

--let's do something slightly different
--this brings me to simply regions and also had to remove "income" levels which they inexplicably included in this column.

select location, MAX(Total_Deaths) as TotalDeathCount
from PortfolioDatabase.dbo.CovidDeaths
where continent IS NULL And location NOT LIKE '%income%'
Group By location
order by TotalDeathCount Desc

--Global Numbers
--Total death percentage as of 6-4-2023 is .9%

SELECT SUM(new_cases) as Total_Cases, SUM(new_deaths) as Total_Deaths, 
       CASE WHEN SUM(new_cases) <> 0 
            THEN SUM(new_deaths) / NULLIF(SUM(new_cases), 0) * 100 
            ELSE NULL 
       END AS DeathPercentage
FROM PortfolioDatabase.dbo.CovidDeaths
where continent is not null
--GROUP BY date
ORDER BY 1, 2;

--Looking at total population vs. Vaccinations worldwide
--I think I got what I needed with this, but was told by someone else I should use a CTE

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as RunningTotalVacPerCountry
, Sum(vac.new_vaccinations/dea.population*100) OVER (Partition by dea.location order by dea.location, dea.date) as PercentVaccinated
From PortfolioDatabase..CovidVaccinations vac
JOIN PortfolioDatabase..CovidDeaths dea
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2, 3

--Using a CTE
--Yup, looks the same. Not sure why the CTE was necessary exactly. But now I know two ways to do it.

With PopvsVac (Continent, Location, Date, Population,New_Vaccinations, RunningTotalVacPerCountry)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as RunningTotalVacPerCountry
From PortfolioDatabase..CovidVaccinations vac
JOIN PortfolioDatabase..CovidDeaths dea
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)

Select *, (RunningTotalVacPerCountry/Population)*100 as RollingPercentageVaccinated
From PopvsVac

--now with Temp Table


DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert Into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioDatabase..CovidVaccinations vac
JOIN PortfolioDatabase..CovidDeaths dea
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

--Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
, Sum(vac.new_vaccinations/dea.population*100) OVER (Partition by dea.location order by dea.location, dea.date) as PercentVaccinated
From PortfolioDatabase..CovidVaccinations vac
JOIN PortfolioDatabase..CovidDeaths dea
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2, 3

Create View CountriesByInfectionRate as
select location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
from PortfolioDatabase.dbo.CovidDeaths
where continent IS NOT NULL
Group By location, population

Create View TotalDeathCountPerContinent as
select location, MAX(Total_Deaths) as TotalDeathCount
from PortfolioDatabase.dbo.CovidDeaths
where continent IS NULL And location NOT LIKE '%income%'
Group By location

Create View ChangingDeathRateUS as
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioDatabase.dbo.CovidDeaths
where location like '%states%'
--order by 1, 2