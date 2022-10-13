-- The dataset is extracted from https://ourworldindata.org/covid-deaths.
-- I've created the Covid Death and Covid Vaccination csv files using the dataset extracted.
-- The covid_death and covid_vac tables are created and the data are imported using the csv files.

-- 1. Total Cases vs Total Deaths in Singapore
-- Shows likelihood of dying if you contract covid in your country
-- In Oct 2022, the likelihood of a person dying when he/she contract Covid in Singapore is 0.08%.
SELECT
	location,
	date,
	total_cases,
	total_deaths,
	ROUND((total_deaths::NUMERIC/total_cases)*100,2) AS death_percent
FROM covid_death
WHERE continent IS NOT NULL AND location='Singapore'
ORDER BY date;

-- 2. Total Cases vs Population in Singapore
-- Shows what percentage of population infected with Covid
-- As of Oct 2022, 35.9% of the population is infected with Covid
SELECT
	location,
	date,
	total_cases,
	population,
	ROUND((total_cases::NUMERIC/population)*100,5) AS population_affected_percent
FROM covid_death
WHERE continent IS NOT NULL AND location='Singapore'
ORDER BY date;

-- 3. Total cases and death globally
SELECT
	SUM(new_cases) AS total_cases,
	SUM(new_deaths) AS total_deaths,
	ROUND((SUM(new_deaths::NUMERIC)/SUM(new_cases))*100,3) AS death_percentage
FROM covid_death
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- 4. Top 3 Countries with the highest death count
SELECT 
	location,
	max(total_deaths) AS total_deaths
FROM covid_death
WHERE continent IS NOT NULL and total_deaths IS NOT NULL
GROUP BY location
ORDER BY 2 DESC
LIMIT 3;

-- 5. Total death cases count by continent
-- Europe has the higest number of death cases
WITH total_death_cases AS (
	SELECT 
		continent,
		location,
		max(total_deaths) AS total_death
	FROM covid_death
	WHERE continent IS NOT NULL
	GROUP BY continent, location
	ORDER BY 2 DESC)
SELECT 
	continent,
	SUM(total_death) AS total
FROM total_death_cases
GROUP BY continent
ORDER BY total DESC;

-- 6. Highest Infection Rate by location
-- Cyprus has the highest infection rate
SELECT
	location,
	population,
	MAX(total_cases) AS highest_infection_rate,
	ROUND(MAX((total_cases::NUMERIC/population))*100,2) AS highest_infection_rate_percent
FROM covid_death
WHERE population IS NOT NULL AND total_cases IS NOT NULL
GROUP BY location, population
ORDER BY highest_infection_rate_percent DESC;

-- With date
SELECT
	location,
	date,
	population,
	MAX(total_cases) AS highest_infection_rate,
	ROUND(MAX((total_cases::NUMERIC/population))*100,2) AS highest_infection_rate_percent
FROM covid_death
WHERE population IS NOT NULL AND total_cases IS NOT NULL
GROUP BY location, date, population
ORDER BY highest_infection_rate_percent DESC;

-- 7. Total Population vs Vaccinations
-- Perform rolling count for the people vaccinated with window function
-- Use CTE in order to perform the calculation using the created rolling people vaccinated data
WITH pop_vac AS (
	SELECT
		d.continent,
		d.location,
		d.date,
		d.population,
		v.new_people_vaccinated_smoothed,
		SUM(v.new_people_vaccinated_smoothed) OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_pop_vac
	FROM covid_death AS d
	JOIN covid_vac AS v
		ON d.location = v.location
		AND d.date = v.date
	WHERE d.continent IS NOT NULL
	ORDER BY 1, 2, 3)
SELECT 
	*,
	ROUND(rolling_pop_vac::NUMERIC/population*100, 5) AS population_vaccinated_percent
FROM pop_vac
ORDER BY 2, 3;

-- Create view to store data
CREATE VIEW vac_population_percent AS
SELECT
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_people_vaccinated_smoothed,
	SUM(v.new_people_vaccinated_smoothed) OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_vac
FROM covid_death AS d
JOIN covid_vac AS v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL;

-- Looking at Singapore only
-- Total cases, death and vaccinations in Singapore
SELECT
	SUM(d.new_cases) AS total_cases,
	SUM(d.new_deaths) AS total_deaths,
	ROUND((SUM(d.new_deaths::NUMERIC)/SUM(d.new_cases))*100,3) AS death_percentage,
	ROUND((MAX(v.people_fully_vaccinated::NUMERIC)/MAX(d.population))*100, 2) AS total_people_vac_percent,
	MAX(v.total_vaccinations) AS total_vaccinations,
	MAX(v.total_boosters) AS total_boosters
FROM covid_death AS d
JOIN covid_vac AS v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL AND d.location='Singapore'
ORDER BY 1, 2;

