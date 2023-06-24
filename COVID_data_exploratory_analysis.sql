--preview of a table
select * from cdeath;

--altering data type 
ALTER TABLE cdeath 
ALTER COLUMN population type bigint
USING population::bigint;


-- united states %death=total cases/total deaths;
select location,date, total_deaths,total_cases,
(total_deaths/total_cases*100::float) as percent_death
from cdeath
where location ilike '%states'
order by date
;

--percent infection from the total population
select location,date, population,total_cases,
(total_cases/population*100::float) as percent_infection
from cdeath
where location ilike '%states'
order by date
;

-- sum of deaths in United Sates per year
select extract(year from date) as yr, location, sum(total_deaths) as yearly_death, 
sum(total_cases) as yearly_cases,(sum(total_deaths)/sum(total_cases)*100::float) as percent_death
from cdeath
where location ilike '% States'
group by yr,location
--order by yr,location
;


-- sum of deaths in United Sates for year 2022 on monthly basis
select extract(year from date) as yr, extract(month from date) as mon, location, 
sum(total_deaths) as monthly_death, sum(total_cases) as monthly_cases,
(sum(total_deaths)/sum(total_cases)*100::float) as percent_death
from cdeath
where location ilike '% States' and extract(year from date)='2022'
group by yr, mon, location
--order by yr,location
;


-- sum of deaths in United Sates on monthly basis
select extract(year from date) as yr, extract(month from date) as mon, location, 
sum(total_deaths) as monthly_death, sum(total_cases) as monthly_cases,
(sum(total_deaths)/sum(total_cases)*100::float) as percent_death
from cdeath
where location ilike '% States'
group by yr, mon, location
--order by yr,location
;



--infection rate per location

select location, population, total_cases, 
(total_cases/population)*100::float as inf_rate
from cdeath;


-----infection rate aggregated per country
select location, avg(population) as pop, avg(total_cases) as avg_cases, 
--(total_cases/population)*100::float as inf_rate
avg(total_cases/population)*100::float as inf_rate
from cdeath
group by location
order by location
;

-----death rate aggregated per country
select location,avg(total_cases) as tot_cases,avg(total_deaths),
avg(total_deaths)/avg(total_cases)*100::float as death_rate
from cdeath
where location ilike '%States'
group by location												 
--order by location
;

--highest infection rate location vs pop

select location, population, max(total_cases) as max_case, 
max(total_cases/population)*100::float as inf_rate
from cdeath
--where location ilike '%states'
group by location, population
--order by inf_rate desc
;

--highest death rate location

select location, population, max(total_deaths) as max_death
--max(total_deaths/total_cases)*100::float as death_rate
from cdeath
where continent is not null or total_deaths is not null
group by location, population

order by location
--max_death desc
; 


--stat by continent
--1. total death by contineny
select location, max(total_cases) as max_inf
--avg(total_cases/population)*100 as inf_rate
from cdeath
where continent is null and location in ('Low income','High income')
group by location
order by location
;
-- 2. death rate by continent
select location, max(total_cases) as max_inf,
avg(total_cases/population)*100 as inf_rate
from cdeath
where continent is null 
group by location
order by location
;
-- 2. death rate by continent broken down by date

select location, extract(year from date) as yr, max(total_cases) as max_inf,
avg(total_cases/population)*100 as inf_rate
from cdeath
where continent is null 
group by location, yr
order by location
;

--Global infection rate
select location, avg(population) as total_pop,max(total_cases) as max_inf, avg(total_cases/population)*100 as inf_rate
from cdeath
where continent is null and location='World'
group by location
--order by location
;

--Global infection rate by year
select location, extract(year from date) as yr,
max(total_cases) as max_inf, avg(total_cases/population)*100 as inf_rate
from cdeath
where continent is null and location='World'
group by location,yr
order by yr
;

--global total cases
select location, sum(new_cases) as total_new_cases,
avg(population) as total_pop
from cdeath
where continent is null and location='World'
group by location
--order by location
;

--join the two tables
--select * from cvax;

select *
from cdeath
join cvax
on cdeath.location=cvax.location 
and cdeath.date=cvax.date
;

--looking at population vs vaxs
select cdeath.continent,cdeath.location, cdeath.date, cdeath.population,
total_vaccinations, new_vaccinations,
sum(cvax.new_vaccinations) over (partition by cdeath.location order by cdeath.location,cdeath.date) as cummulative_vax, 
cummulative_vax/cdeath.population as vax_rate
from cdeath
join cvax
on cdeath.location=cvax.location 
and cdeath.date=cvax.date
--where cdeath.location='Albenia'
;

---creating a new table from results???
create table table1
--with new_tab(continent,location, date, population,total_vaccinations, new_vaccinations,cummulative_vax)
as(

select cdeath.continent,cdeath.location, cdeath.date, cdeath.population,
total_vaccinations, new_vaccinations,
sum(cvax.new_vaccinations) over (partition by cdeath.location order by cdeath.location,cdeath.date) as cummulative_vax
from cdeath
join cvax
on cdeath.location=cvax.location 
and cdeath.date=cvax.date
)
;
select *, cummulative_vax/population as vax_rate
from table1
--new_tab
;

select * from table1;

--creating view to store data for later visulizations

create view percentpopulationvaccinated as
(select cdeath.continent,cdeath.location, cdeath.date, cdeath.population,
total_vaccinations, new_vaccinations,
sum(cvax.new_vaccinations) over (partition by cdeath.location order by cdeath.location,cdeath.date) as cummulative_vax
from cdeath
join cvax
on cdeath.location=cvax.location 
and cdeath.date=cvax.date
)
;


--Global infection rate by year
create view GlobalInfectionRatebyYear as
(select location, extract(year from date) as yr,
max(total_cases) as max_inf, avg(total_cases/population)*100 as inf_rate
from cdeath
where continent is null and location='World'
group by location,yr
order by yr)
;

--infection rate by continent broken down by year
create view continental_infection_rate_per_year as
(
select location, extract(year from date) as yr, max(total_cases) as max_inf,
avg(total_cases/population)*100 as inf_rate
from cdeath
where continent is null and location in ('Africa','Asia','Europe','North America','Oceania','South America')
group by location, yr
order by location
)
;

-----death rate aggregated per country
create view deathratepercountry
as
(select location,avg(total_cases) as tot_cases,avg(total_deaths),
avg(total_deaths)/avg(total_cases)*100::float as death_rate
from cdeath
where continent is not null --and location not in ('Africa','Asia','Europe','North America','Oceania','South America')
--where location ilike '%States'
group by location												 
--order by location
)
;

--total death count per continent
create view totaldeathcount as
select location, sum(new_deaths)as totaldeathcount
from cdeath
where continent is null and location in ('Africa','Asia','Europe','North America','Oceania','South America')
group by location
order by totaldeathcount desc
;