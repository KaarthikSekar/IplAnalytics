use iplmatches;


-- Check for NULL values in key columns (WinningTeam, Margin, Player_of_Match)
select count(*) as totalrows,
SUM(CASE WHEN WinningTeam IS NULL THEN 1 ELSE 0 END) AS null_WinningTeam,
SUM(CASE WHEN Margin IS NULL THEN 1 ELSE 0 END) AS null_Margin,
SUM(CASE WHEN Player_of_Match IS NULL THEN 1 ELSE 0 END) AS null_Player_of_Match
from iplmatches;


-- Count total matches and verify there are no duplicate ID entries
select id, count(*) as occurences 
from iplmatches
group by id
having count(*)>1;

-- Find matches where Margin is NULL — are they super overs or no results?
-- Find matches where Margin is NULL
SELECT ID, Season, Team1, Team2, WinningTeam, WonBy, SuperOver, Margin, method
FROM iplmatches
WHERE Margin IS NULL;

-- Standardize WonBy values — what are all the distinct values?
-- Check all distinct WonBy values
SELECT DISTINCT WonBy, COUNT(*) AS match_count
FROM iplmatches
GROUP BY WonBy;

-- EDA (Exploratory Data Analysis)

-- How many matches were played each season?
select distinct season, count(*) as totalcount 
from iplmatches
group by season
order by season;

-- Which venues hosted the most matches?
select distinct venue, count(*) as totalcount 
from iplmatches
group by venue
order by totalcount desc;

-- How many unique teams have played in the IPL?

select count(*) as totalteamno from (
select Team1 as team from iplmatches
union 
select Team2 as team from iplmatches
) as uniqueteams;

-- What is the breakdown of wins by WonBy (Runs vs Wickets)?
select distinct WonBy, 
count(*) as matchcount,
((count(*)*100)/ (SELECT COUNT(*) FROM iplmatches)) as percentage 
from iplmatches
group by WonBy;


-- Team Performance

-- Which team has won the most matches overall?
select count(*) as winningteamcount, winningTeam 
from iplmatches
group by winningTeam 
order by winningteamcount desc;

-- Which team has the highest win % per season?
SELECT 
    Season,
    teams,
    SUM(CASE WHEN teams = WinningTeam THEN 1 ELSE 0 END) AS matches_won,
    ROUND(
        SUM(CASE WHEN teams = WinningTeam THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS win_percentage
FROM (
    SELECT Season, team1 AS teams, WinningTeam FROM iplmatches
    UNION ALL
    SELECT Season, team2 AS teams, WinningTeam FROM iplmatches
) t
GROUP BY Season, teams;



-- Which team wins the most when batting first vs chasing?
SELECT COUNT(*) AS wins, WonBy
FROM iplmatches
GROUP BY WonBy;



-- Which team has the most final appearances? (filter MatchNumber = 'Final')

-- select distinct team1, team2
-- from iplmatches
-- where MatchNumber = 'Final'

select teams, count(*) as appearances from (
select team1 as teams from iplmatches
where MatchNumber = 'Final'
union all
select team2 as teams from iplmatches
where MatchNumber = 'Final'
) as finalteams
group by teams;

-- Toss impact
SELECT 
    COUNT(*) AS total_matches,
    SUM(CASE WHEN TossWinner = WinningTeam THEN 1 ELSE 0 END) AS toss_winner_wins,
    ROUND(
        SUM(CASE WHEN TossWinner = WinningTeam THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS win_percentage
FROM iplmatches;

-- Toss decision preference
SELECT 
    TossWinner,
    TossDecision,
    COUNT(*) AS times_chosen
FROM iplmatches
GROUP BY TossWinner, TossDecision
ORDER BY TossWinner, times_chosen DESC;

-- Venue batting first advantage
SELECT 
    Venue,
    COUNT(*) AS total_matches,
    SUM(CASE WHEN WonBy = 'Runs' THEN 1 ELSE 0 END) AS batting_first_wins,
    ROUND(
        SUM(CASE WHEN WonBy = 'Runs' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS win_percentage
FROM iplmatches
GROUP BY Venue
ORDER BY win_percentage DESC;

-- City with most matches
SELECT 
    City,
    COUNT(*) AS total_matches
FROM iplmatches
GROUP BY City
ORDER BY total_matches DESC;

-- Bonus: Toss impact by venue
SELECT 
    Venue,
    COUNT(*) AS total_matches,
    SUM(CASE WHEN TossWinner = WinningTeam THEN 1 ELSE 0 END) AS toss_wins,
    ROUND(
        SUM(CASE WHEN TossWinner = WinningTeam THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS toss_win_percentage
FROM iplmatches
GROUP BY Venue
ORDER BY toss_win_percentage DESC;

-- Most Player of the Match awards overall
SELECT 
    Player_of_Match,
    COUNT(*) AS awards
FROM iplmatches
GROUP BY Player_of_Match
ORDER BY awards DESC;

-- Most Player of the Match awards in a single season
SELECT 
    Season,
    Player_of_Match,
    COUNT(*) AS awards
FROM iplmatches
GROUP BY Season, Player_of_Match
ORDER BY awards DESC;

-- Player dominating across multiple teams
SELECT 
    Player_of_Match,
    COUNT(DISTINCT WinningTeam) AS teams_played_for,
    COUNT(*) AS total_awards
FROM iplmatches
GROUP BY Player_of_Match
HAVING COUNT(DISTINCT WinningTeam) > 1
ORDER BY total_awards DESC;

-- Top 10 Player of the Match winners
SELECT 
    Player_of_Match,
    COUNT(*) AS awards
FROM iplmatches
GROUP BY Player_of_Match
ORDER BY awards DESC
LIMIT 10;

-- Average winning margin (runs) per season
SELECT 
    Season,
    ROUND(AVG(CASE WHEN WonBy = 'Runs' THEN Margin END), 2) AS avg_runs_margin
FROM iplmatches
GROUP BY Season
ORDER BY Season;

-- Season with most super overs
SELECT 
    Season,
    COUNT(*) AS super_over_matches
FROM iplmatches
WHERE SuperOver = 'Y'
GROUP BY Season
ORDER BY super_over_matches DESC;

-- Most competitive season (lowest average margin)
SELECT 
    Season,
    ROUND(AVG(Margin), 2) AS avg_margin
FROM iplmatches
GROUP BY Season
ORDER BY avg_margin ASC;

-- Matches won by runs vs wickets per season
SELECT 
    Season,
    SUM(CASE WHEN WonBy = 'Runs' THEN 1 ELSE 0 END) AS wins_by_runs,
    SUM(CASE WHEN WonBy = 'Wickets' THEN 1 ELSE 0 END) AS wins_by_wickets
FROM iplmatches
GROUP BY Season
ORDER BY Season;

-- Team with best record at each venue (home advantage)
SELECT 
    Venue,
    WinningTeam,
    COUNT(*) AS wins,
    RANK() OVER (PARTITION BY Venue ORDER BY COUNT(*) DESC) AS rnk
FROM iplmatches
GROUP BY Venue, WinningTeam;

-- Toss advantage at specific venues
SELECT 
    Venue,
    COUNT(*) AS total_matches,
    SUM(CASE WHEN TossWinner = WinningTeam THEN 1 ELSE 0 END) AS toss_wins,
    ROUND(
        SUM(CASE WHEN TossWinner = WinningTeam THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS toss_win_percentage
FROM iplmatches
GROUP BY Venue
ORDER BY toss_win_percentage DESC;

-- Umpire who officiated most matches
SELECT 
    umpire,
    COUNT(*) AS matches_officiated
FROM (
    SELECT Umpire1 AS umpire FROM iplmatches
    UNION ALL
    SELECT Umpire2 AS umpire FROM iplmatches
) u
GROUP BY umpire
ORDER BY matches_officiated DESC;

-- Head-to-head record between teams
SELECT 
    team1,
    team2,
    COUNT(*) AS total_matches,
    SUM(CASE WHEN WinningTeam = team1 THEN 1 ELSE 0 END) AS team1_wins,
    SUM(CASE WHEN WinningTeam = team2 THEN 1 ELSE 0 END) AS team2_wins
FROM iplmatches
GROUP BY team1, team2
ORDER BY total_matches DESC;




