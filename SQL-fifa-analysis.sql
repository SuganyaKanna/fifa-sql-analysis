create database fifa;

select * from teams;

select * from players;

------------------------------------
-- Data Cleaning And Preprocessing

--1. Find players with missing “club_name” or “value_eur”.

select id, fullname 
from players 
where club is null or ValueEur is null;

------ Both Club and value_eur columns doesn't have any null values so returning empty results.

-----------------------------------------------------------------------------------------------------------
--2. Standardize “work_rate” column to have consistent formatting (e.g., convert “High / Medium” → “High/Medium”).

/* 
The dataset does not contain a work_rate column. Instead, it includes AttackingWorkRate and DefensiveWorkRate, 
each storing a single value (‘Low’, ‘Medium’, or ‘High’). 
Since these values are already standardized, no further cleaning is required 
*/

/* 
UPDATE players
SET attacking_work_rate = REPLACE(attacking_work_rate, ' / ', '/'),
    defensive_work_rate = REPLACE(defensive_work_rate, ' / ', '/');
*/
--------------------------------------------

--3. Extract the primary position of each player from the player_positions column (pick the first position before a comma).

select id, fullname,
case 
    when charindex(',',positions) >0 then left(positions, charindex(',',positions)-1)
    else positions 
end 
as primary_position
from players;

-------------------------------------------
--4. Convert “height_cm” and “weight_kg” into numeric form and remove outlier players (e.g., height < 150 cm or > 220 cm).

-- lets check the data type of height and weight columns.
select * from players 
where TRY_CAST(height as int) is null 
and height is not null;

select * from players 
where TRY_CAST(weight as int) is null 
and weight is not null; --- already both columns are int type only.

-- lets find outliers count.
-- height < 150 cm or > 220 cm (height outliers)

select count(*) as height_outliers
from players 
where height < 150 or height > 220; -- no height outliers detected

-- weight < 400 cm or > 1500 cm (weight outliers)

select count(*) as weight_outliers
from players
where weight <40 and weight > 150 -- no weight outliers as well. so no need to remove the outliers.


--------------------------------------------------------

--5. Normalize “preferred_foot”: ensure all values are either “Left” or “Right”.

select distinct preferredfoot 
from players; ---- all values are already normalized.


-----------------------------------------------------------

-- Player Analysis

--6. Top “potential vs overall” gap: List the top 15 players who have the highest potential - overall difference.

/*
select top 15 id, fullname, (potential - overall) as gap
from players 
order by gap desc;
*/

select top 15 id, fullname, growth as gap 
from players 
order by gap desc;

------------------------------------------------------------

--7. Average overall rating by nationality: For each country (nationality), 
--   compute the average overall rating, but only include nationalities that have at least 50 players.

select nationality, count(distinct id) as player_count, avg(overall) as avg_rating 
from players 
group by nationality
having count(distinct id)>=50
order by avg_rating desc;

---------------------------------------------------------------select top 2 * from players

--8. Young high-rated players: Identify all players who are ≤ 21 years old and have overall rating ≥ 80.

select id, fullname, age, overall 
from players 
where age <=21 and overall >=80
order by age, overall desc

-------------------------------------------------------

--9. Fastest players: Return top 10 players by pace attribute, along with their club and position

select top 10 id, fullname, pacetotal, club, Positions 
from players 
order by pacetotal desc;

-------------------------------------------------------

--10. Average attribute by primary position: For each primary position (e.g., “ST”, “CM”, “CB”), 
--    compute average values of the following attributes: pace, shooting, passing, dribbling, defending, physic.

with prim_positions 
as (
    select id,
    case 
        when charindex(',',positions)>0
            then left(positions,charindex(',',positions)-1 )
        else 
            positions 
    end 
    as primary_position
    from players
)
select primary_position, count(p.id) as player_count,
avg(pacetotal) as avg_pace,
 avg(shootingtotal) as avg_shooting, 
 avg(passingtotal) as avg_passing, 
 avg(dribblingtotal) as avg_dribbling, 
 avg(defendingtotal) as avg_defending, 
 avg(physicalitytotal) as avg_physic
from players p
inner join prim_positions pp 
on p.id = pp.id
group by primary_position;

----------------------------------------------------------- 

--11. Over-valued release clause: Find players whose release_clause_eur is more than 5× their value_eur.

select id, fullname, valueEur, releaseClause, ReleaseClause/ValueEUR as ratio
from players 
where ReleaseClause > 5*ValueEUR --try 3*valueEur
order by ReleaseClause desc;

-----the maximum ratio found is 3. so 5 * valueEur is not returning any result


---------------------------------------------------------------

--12. Distribution of preferred foot: Show how many players are left-footed vs right-footed, grouped by league (if league_name is present).

select t.league, 
sum(
    case 
        when p.preferredFoot = 'Right' 
            then 1 
        else 0 
    end) as right_foot,
sum(
    case 
        when preferredFoot = 'Left'
            then 1 
        else 0 
    end) as left_foot
from players p 
inner join teams t 
on p.club = t.name
group by t.league;

----------------------------------------------------------------

--13. Low skill-moves or weak foot: List players who have skill_moves = 1 or weak_foot = 1.

select id, fullname, SkillMoves, WeakFoot
from players 
where SkillMoves = 1 or WeakFoot = 1;

-----------------------------------------------------------------

-----------------       Team & League Insights

--14. Average player overall by team: Join players and teams tables, and compute the average overall rating for each club, 
--    then list the top 15 teams by this metric.

select top 15 t.name as team_name, avg(p.overall)as avg_overall_per_team, count(p.id) as players_per_team
from players p 
inner join teams t 
on p.club = t.name
group by t.name
order by avg_overall_per_team desc;

-------------------------------------------------------------------

--15. High-wage leagues: Find leagues where the average weekly wage of players is above a certain threshold (e.g., €40,000).

select t.league, avg(p.wageEur) as avg_weekly_wage 
from teams t 
inner join players p 
on t.name = p.club
group by t.League 
having avg(p.wageEur) >40000
order by avg_weekly_wage desc;

---------------------------------------------------------------------

--16. Clubs with most top-tier players: Identify clubs that have the most number of players with overall ≥ 85.

select top 10 club, count(id) as No_of_top_tier_players 
from players 
where overall >= 85
group by club 
order by No_of_top_tier_players desc;

---------------------------------------------------------------------

--17. League-level summary: For each league, compute average overall, potential, value_eur, and wage_eur.

select t.league, 
avg(p.overall) as avg_overall, 
avg(p.potential) as avg_potential, 
avg(cast(p.valueEur as bigint)) as avg_value_euro, 
avg(cast(p.wageEur as bigint)) as weekly_wage  
from players p 
inner join teams t 
on p.club = t.name
group by t.league
order by avg_overall desc;

------------------------------------------------------------------------

--18. Player composition in clubs: For each team, compute the ratio of attackers : midfielders : defenders (use primary position extracted earlier).

with prime 
as (
    select id, club, 
    case 
        when charindex(',',positions) >0 
            then left(positions, charindex(',',positions)-1) 
        else 
            positions
    end as primary_positions
    from players
), 
position_group 
as (
    select club, primary_positions, 
    case 
        when primary_positions in ('ST', 'LW', 'RW', 'CF', 'LF', 'RF')
            then 'Attacker'
        when primary_positions in ('CM', 'CDM', 'CAM', 'LM', 'RM')
            then 'Mid fielder'
        when primary_positions in ('CB', 'LB', 'RB', 'LWB', 'RWB')
            then 'Defender'
        else 'other'
    end as groups
    from prime
)
select club, 
sum(case when groups = 'Attacker' then 1 else 0 end) as attackers,
sum(case when groups = 'Mid fielder' then 1 else 0 end) as midfielders, 
sum(case when groups = 'Defender' then 1 else 0 end) as defenders
from position_group
group by club
order by club;

------------------------------------------------------------------------

--19. Team vs average player rating discrepancy: 
--    Show teams for which the overall rating (in the teams table) differs by ≥ 5 points from the average overall of their players.

select t.name, t.overall, avg(p.overall) as avg_plyers_overall, abs(t.overall - avg(p.overall)) as gap
from teams t 
inner join players p 
on t.name = p.club 
group by t.name, t.overall
having abs(t.overall - avg(p.overall)) >=5
order by gap desc;

------------------------------------------------------------------------

------------------------    Advanced SQL

--20. Top 3 players per club by overall: Use window functions to rank players in each club by their overall rating, and list the top 3.


with players_per_club
as (
    select club, fullname, overall, 
    dense_rank() over(partition by club order by overall desc) as players_rank
    from players   
)
select club, fullname, overall, players_rank 
from players_per_club 
where players_rank in (1,2,3)
order by Club;

------------------------------------------------------------------------

--21. Undervalued players: Find players such that (value_eur / overall) is among the lowest 10% of players having overall ≥ 80 
--    (i.e., good rating but cheap).

with undervalued_players 
as (
    select id, fullname, overall, valueEur, (valueEur/overall) as ratio
    from players
    where overall >= 80
),
percentile_groups 
as (
    select * , 
    ntile(10) over( order by ratio) as tiles
    from undervalued_players
)
select * 
from percentile_groups 
where tiles = 1 
order by ratio;

------------------------------------------------------------------------

--22. Annual wage cost per club: Use a CTE to calculate total wage cost per club assuming wage_eur is weekly (multiply by 52).

with annual_cacl
as(
    select club, wageEur, (wageEur *52) as Annual_wage 
    from players
)
select club, sum(wageEur) as weekly_cost, sum(annual_wage) as total_annual_cost
from annual_cacl
group by club 
order by total_annual_cost desc;

------------------------------------------------------------------------

--23. Improvement potential ranking: Calculate (potential - overall) / age for each player; list the top 20 players by this metric.

select top 20 id, fullname, potential, overall, age,
round(cast(potential-overall as float)/nullif(age,0),2) as improvement_ranking 
from players 
order by improvement_ranking desc;

------------------------------------------------------------------------

--24. Percentile ranking of attributes: Using window functions, 
--    compute percentile rank of each player for pace, shooting, and dribbling among all players.

select id, fullname, 
round(percent_rank() over(order by pacetotal desc),3) as pace_rank, 
round(percent_rank() over(order by shootingtotal desc),3) as shooting_rank,
round(percent_rank() over(order by dribblingtotal desc ),3) as dribbling_rank
from players
order by pace_rank desc;

------------------------------------------------------------------------

--25. Efficient high-performing players: List players whose overall is above their club’s average and whose wage_eur is below their club’s average.

with club_calc 
as (
    select club, avg(overall) as club_overall, avg(wageEur) as club_wage
    from players
    group by club
)
select p.id, p.fullname, p.club, p.overall,p.wageEur,
cc.club_overall, cc.club_wage
from players p 
inner join club_calc cc
on p.club = cc.club 
where p.overall > cc.club_overall 
and p.wageEur < cc.club_wage
order by p.overall desc;


---------------------------------------- The End -------------------------------------------------



