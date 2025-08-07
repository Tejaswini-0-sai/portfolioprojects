SELECT * FROM portfolioprojects..CovidDeaths1;

SELECT location,date,total_cases,new_cases,total_deaths,population
FROM portfolioprojects..CovidDeaths1
ORDER BY 1,2;

--looking at total cases vs Total deaths 
ALTER TABLE portfolioprojects..CovidDeaths1
ALTER COLUMN total_deaths INT;

ALTER TABLE portfolioprojects..CovidDeaths1
ALTER COLUMN total_cases INT;

ALTER TABLE portfolioprojects..CovidDeaths1
ALTER COLUMN date DATE ;

ALTER TABLE portfolioprojects..CovidDeaths1
ALTER COLUMN population BIGINT;

SELECT location,date,total_cases,new_cases,total_deaths,population
FROM portfolioprojects..CovidDeaths1
WHERE total_cases=0 AND total_deaths!=0;


--filter any country to know the totaldeaths and its percentage 
SELECT location,date,total_cases,total_deaths,ROUND((CAST(total_deaths AS FLOAT)/total_cases)*100,4) As deathpercent
FROM portfolioprojects..CovidDeaths1
WHERE total_cases!=0 AND location like '%states%'
ORDER BY 2;

--Shows what percent of population got COVID 
SELECT location,date,total_cases,population,ROUND((CAST(total_cases AS FLOAT)/population)*100,4) As percentpopulationinfected
FROM portfolioprojects..CovidDeaths1
WHERE total_cases!=0 AND location like '%states%'
ORDER BY 2;

SELECT location,date,total_cases,population,ROUND((CAST(total_cases AS FLOAT)/population)*100,4) As percentpopluationinfected
FROM portfolioprojects..CovidDeaths1
WHERE total_cases!=0 AND location = 'India'
ORDER BY 2;

--looking at countries with Highest Infection Rate compared to population 
SELECT location,population,max(total_cases)AS infected, MAX(ROUND((CAST(total_cases AS FLOAT)/population)*100,4)) AS percentPopInfected 
FROM portfolioprojects..CovidDeaths1
WHERE population!=0
GROUP BY location,population
ORDER BY percentPopInfected DESC;

--Showing countries with Highest Death Count Per Population
SELECT location,population,max(total_deaths)AS died, MAX(ROUND((CAST(total_deaths AS FLOAT)/population)*100,4)) AS percentPopdied
FROM portfolioprojects..CovidDeaths1
WHERE population!=0
GROUP BY location,population
ORDER BY percentPopdied DESC;

--Break deathcounts by Continent 
SELECT continent,max(total_deaths)AS died	
FROM portfolioprojects..CovidDeaths1
WHERE continent!=' '
GROUP BY continent
ORDER BY died DESC;

ALTER TABLE portfolioprojects..CovidDeaths1
ALTER COLUMN new_cases INT;

ALTER TABLE portfolioprojects..CovidDeaths1
ALTER COLUMN new_deaths INT;

--Global numbers 
SELECT sum(new_cases )AS total_cases, SUM(new_deaths) AS total_deaths,
(SUM(CAST(new_deaths AS FLOAT))/sum(new_cases))*100 AS Deathpercentage
FROM portfolioprojects..CovidDeaths1
WHERE  new_cases!=0 AND continent !=' '
ORDER BY total_deaths ASC;



--Looking total population Vs vaccinations 
SELECT dea.continent,dea.date,dea.location, dea.population, vac.new_vaccinations, 
 SUM(CONVERT(INT,vac.new_vaccinations))OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) As rolledpeoplevaccinated --(rolledpeopevaccinated/population)*100
FROM portfolioprojects..CovidDeaths1 dea
JOIN portfolioprojects..covidvaccinations vac
  ON dea.location=vac.location AND
   dea.date=vac.date
   WHERE dea.continent!=' '
   ORDER BY 2,3;

--CTE 
WITH popvsvac(continent, date,location,population,new_vaccinations,rolledpeoplevaccinated)
AS
(
SELECT dea.continent,dea.date,dea.location, dea.population, vac.new_vaccinations, 
 SUM(CONVERT(INT,vac.new_vaccinations))OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) As rolledpeoplevaccinated --(rolledpeopevaccinated/population)*100
FROM portfolioprojects..CovidDeaths1 dea
JOIN portfolioprojects..covidvaccinations vac
  ON dea.location=vac.location AND
   dea.date=vac.date
   WHERE dea.continent!=' '
   )
   SELECT population, rolledpeoplevaccinated, (rolledpeoplevaccinated/(CAST(population as FLOAT))) *100
   FROM popvsvac
   Where population!=0

   --Temp Table
 DROP TABLE IF EXISTS #percentpopulationvaccinated;

CREATE TABLE #percentpopulationvaccinated (
    continent NVARCHAR(255),
    report_date DATETIME,
    location NVARCHAR(255),
    population FLOAT,
    new_vaccinations FLOAT,
    rolledpeoplevaccinated FLOAT
);

INSERT INTO #percentpopulationvaccinated (
    continent,
    report_date,
    location,
    population,
    new_vaccinations,
    rolledpeoplevaccinated
)
SELECT 
    dea.continent,
    dea.[date] AS report_date,
    dea.location,
    TRY_CAST(dea.population AS FLOAT) AS population,            -- safer cast
    TRY_CAST(vac.new_vaccinations AS FLOAT) AS new_vaccinations, -- safer cast
    SUM(TRY_CAST(vac.new_vaccinations AS FLOAT)) 
        OVER (PARTITION BY dea.location ORDER BY dea.[date]) AS rolledpeoplevaccinated
FROM portfolioprojects..CovidDeaths1 dea
JOIN portfolioprojects..covidvaccinations vac
    ON dea.location = vac.location AND dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL AND dea.continent != '';

-- Final select
SELECT *,
       (rolledpeoplevaccinated / population) * 100 AS percent_vaccinated
FROM #percentpopulationvaccinated
  WHERE population!=0;
  DROP VIEW IF EXISTS Percentpopulationvaccinated;
  USE portfolioprojects;
Create view Percentpopulationvaccinated as
SELECT dea.continent,dea.date,dea.location, dea.population, vac.new_vaccinations, 
 SUM(CONVERT(INT,vac.new_vaccinations))OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) As rolledpeoplevaccinated --(rolledpeopevaccinated/population)*100
FROM portfolioprojects..CovidDeaths1 dea
JOIN portfolioprojects..covidvaccinations vac
  ON dea.location=vac.location AND
   dea.date=vac.date
   WHERE dea.continent!=' '
   --ORDER BY 2,3;  






