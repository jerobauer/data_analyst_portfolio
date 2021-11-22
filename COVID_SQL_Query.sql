/*
COVID-19 Data Exploration based on COVID deaths report on Our World in Data (https://ourworldindata.org/covid-deaths)
The original file was split into smaller tables: coivd_deaths and covid_vaccinations.
Some of these queries answered general questions about the infections and other allowed me to create a Tableau dashboard: https://public.tableau.com/app/profile/j.bs/viz/COVIDInfectionsDashboard_16375325729890/L-Dash

Tool: Microsoft SQL SMS 18
Skills used:
	- Aggregate functions
	- Window functions
	- Converting data types
	- Joins
	- Temporary tables
	- CTE
*/


-- General overview, checking if loaded values seem correct
SELECT *
FROM portfolio..covid_deaths
WHERE continent IS NOT NULL  -- if continent is null, then location is not a country
ORDER BY location, date


-- Initial basic data
SELECT
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM portfolio..covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Global numbers
SELECT
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS int)) AS total_deaths,
	SUM(CAST(new_deaths AS int))/SUM(New_Cases)*100 AS death_percentage
FROM portfolio..covid_deaths
WHERE continent IS NOT NULL 


-- Ordered list of continents with highest death counts
SELECT
	continent,
	MAX(CAST(total_deaths AS int)) AS total_death_count
FROM portfolio..covid_deaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY total_death_count DESC


-- Full ordered list of countries with highest number of deaths
SELECT
	location,
	MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM portfolio..covid_deaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY 2 DESC


-- Which are the top 10 countries with the highest rate of infection?
SELECT
	TOP 10 ROUND(MAX((total_cases/population)*100),2) AS population_infected_percentage,
	location,
	population,
	MAX(total_cases) AS max_infection_count -- highest value = latest value
FROM portfolio..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY 1 DESC


-- How likely is it to die if you contract COVID in a specific country today (i.e. the latest data ingestion date)?
SELECT
	CAST(deaths.date AS DATE) AS date,
	deaths.location,
	deaths.total_cases,
	deaths.total_deaths,
	ROUND((deaths.total_deaths/deaths.total_cases)*100,2) AS death_percentage
FROM 
	(SELECT
		location,
		MAX(CAST(date as DATE)) AS date
	FROM Portfolio..covid_deaths
	GROUP BY location) AS last
JOIN Portfolio..covid_deaths AS deaths
	ON deaths.location = last.location AND deaths.date = last.date
WHERE deaths.location = 'Argentina'


-- Create a temporary table that shows What percentage of the population of each country was vaccinated at least once, using a CTE.
DROP TABLE IF EXISTS population_vaccinated;
CREATE TABLE population_vaccinated (
	location NVARCHAR(255),
	date DATE,
	population BIGINT,
	people_vaccinated BIGINT,
	percentage_vaccinated_population FLOAT);

WITH joined (location, date, population, people_vaccinated) AS
	(SELECT
		d.location,
		MAX(CAST(d.date as DATE)) AS date,
		d.population,
		MAX(v.people_vaccinated) AS people_vaccinated
	FROM Portfolio..covid_deaths AS d
	JOIN Portfolio..covid_vaccinations AS v
		ON d.location = v.location
	WHERE d.population IS NOT NULL
		AND d.continent IS NOT NULL
	GROUP BY d.location, d.population)
INSERT INTO population_vaccinated
SELECT
	*,
	ROUND((people_vaccinated/population)*100,2) AS percentage_vaccinated_population
FROM joined
ORDER BY 5 DESC