select 
row_number() over(order by appid) game_id,
* 
into steam_staging
from steam_2025_RawData;


--big view of the table

select * from steam_staging order by appid;

-- checking how much rows we have and if appid is legit and have no duplicates

select
count(*) total_rows,
count(distinct appid) unique_appid
from steam_staging;


--testing if we can cast rows with int so we don't have crazy ints, and if there is a game with name = null

SELECT TOP 20
    name,
    required_age,
    dlc_count,
    discount,
    price
FROM steam_staging
WHERE TRY_CAST(required_age AS INT) IS NULL
   OR TRY_CAST(dlc_count AS INT) IS NULL
   OR TRY_CAST(discount AS INT) IS NULL
   OR name IS NULL;

--looking for the 2 games that have name = null

SELECT 
    game_id,
    appid,
    name,
    release_date,
    price,
    developers,
    publishers,
    short_description
FROM steam_staging
WHERE name IS NULL;

--after finding that those two games are proken data, no data refer to the devloppers or the game name we delete them 

DELETE FROM steam_staging
WHERE name IS NULL;

-----------------------------------------------------
--transforming the huge table to more reliable tables
-----------------------------------------------------

--game_core table

SELECT 
    game_id,
    TRY_CAST(appid AS INT) AS appid,
    TRIM(name) AS name,
    CAST(release_date AS DATE) AS release_date,
    TRY_CAST(required_age AS INT) AS required_age,
    CAST(price AS DECIMAL(10,2)) AS price,
    TRY_CAST(discount AS INT) AS discount,
    TRY_CAST(dlc_count AS INT) AS dlc_count,
    windows,
    mac,
    linux
INTO games_core
FROM steam_staging;


select * from games_core;



--game_metrics table

SELECT 
    game_id,
    TRY_CAST(appid AS INT) AS appid,
    TRY_CAST(metacritic_score AS INT) AS metacritic_score,
    TRY_CAST(positive AS INT) AS positive_reviews,
    TRY_CAST(negative AS INT) AS negative_reviews,
    TRY_CAST(recommendations AS INT) AS recommendations,
    TRY_CAST(achievements AS INT) AS achievements,
    TRY_CAST(average_playtime_forever AS INT) AS avg_playtime_forever,
    TRY_CAST(median_playtime_forever AS INT) AS median_playtime_forever,
    TRY_CAST(peak_ccu AS INT) AS peak_ccu,
    estimated_owners
INTO games_metrics
FROM steam_staging;


select * from games_metrics;


-- game meta data table

SELECT 
    game_id,
    TRY_CAST(appid AS INT) AS appid,
    TRIM(developers) AS developers,
    TRIM(publishers) AS publishers,
    TRIM(genres) AS genres,
    TRIM(categories) AS categories,
    TRIM(tags) AS tags,
    TRIM(supported_languages) AS supported_languages
INTO games_metadata
FROM steam_staging;

select * from games_metadata;


--now let's analyze with some requests

------------------------------------------------------------------
--R1: what's the name and the price of top 5 most expensive games.
------------------------------------------------------------------

select top 5 name,price 
from games_core
order by price desc;


--R2: what's the top 10 most reviewed games

select top 10 appid ,positive_reviews+negative_reviews as num_reviews_total
from games_metrics
order by num_reviews_total desc;

--------------------------------------------------------------------------------------------
--R3: 
/*We want to look at high-engagement games. Find the top 5 paid games (price greater than 0)
that have the highest average playtime forever, but only include games that have more than 10,000 total reviews (positive + negative)
so we filter out dead games with fake stats.*/
--------------------------------------------------------------------------------------------

select top 5 m.game_id ,m.appid ,name ,price ,avg_playtime_forever ,positive_reviews+negative_reviews as num_reviews_total
from games_metrics m
join games_core c on m.game_id = c.game_id
where price > 0 and positive_reviews+negative_reviews > 10000
order by avg_playtime_forever desc;

-------------------------------------------------------------------------------------------------------------------
--R4:
/*Business Objective:
Our marketing team is looking to feature great budget-friendly computer games.
They want a list of the top 5 highest-rated games on Metacritic (metacritic_score)
that meet all of the following criteria:

Cost strictly less than $20 but are not completely free.
Support both Windows and Mac.
Have at least 100 total reviews to filter out obscure projects.

Your Deliverable:
Write the SQL query to return the top 5 games, displaying their name, price, metacritic_score, and total reviews.*/
--------------------------------------------------------------------------------------------------------------------

select top 5 name, price, metacritic_score, (positive_reviews + negative_reviews) AS total_reviews
from games_core c
join games_metrics m on c.game_id = m.game_id
where price between 0 and 20   --this line is wrong because it include 0 and 20 (in the request we don't want the free ones) so WHERE price > 0 AND price < 20 is the condition
and windows = 1
and mac = 1
and positive_reviews + negative_reviews >= 100
order by metacritic_score desc;

/*after rening the query behind I found that System Shock® 2 (Classic) is repeated so I tought the data is still not clean 
and when I look at the data more deeply I found that a game can be shared in different regions with the same name but the appid is different.*/

--the query below will show you how much the same names are repeated

select name, count(*) as name_count
from games_core
group by name
having count(*) >1
order by name_count desc

--to verify the appid reason here is a query that show that in the tomb rider game

select name, appid, count(*) over(order by appid) as name_count 
from games_core
where name = 'Shadow of the Tomb Raider: Definitive Edition'

------------------------------------------------------------
--R5:
/*Return the top 10 genres with the highest game counts,
showing the genre name, total game count, and average price,
ordered from the largest genre down.*/
------------------------------------------------------------

select top 10 genres, count(*) [total game count], avg(price) [average price]
from games_metadata m
join games_core c on m.game_id = c.game_id
group by genres
having genres != '[]'
order by count(*) desc
;

-----------------------------------------------------------------------------------------------------------------
--R6:
/*We want to find out if higher-priced games actually have better Metacritic scores or if they're just overhyped.
Pull a list of games priced above $30 that have a valid Metacritic score (IS NOT NULL),
and show me the game name, its price, its Metacritic score, and its developer,
ordered from the highest score down to the lowest.*/
-----------------------------------------------------------------------------------------------------------------

select m.appid, name, price, metacritic_score, developers
from games_metrics m
join games_core c on m.game_id = c.game_id
join games_metadata gm on m.game_id = gm.game_id
where price > 30
and metacritic_score != 0
ORDER BY metacritic_score DESC
;


-----------------------------------------------------------------------------------------------------------------
--R7
/*We want to identify our top-performing free-to-play games to see what drives volume.
Pull a list of all free games (price = 0) that have more than 50,000 positive reviews (positive_reviews > 50000).
Show me the game name, exact price, positive reviews, and the primary developer,
and order the results from the highest number of positive reviews down to the lowest.*/
-----------------------------------------------------------------------------------------------------------------

select c.appid, name, price, positive_reviews, developers
from games_core c
join games_metrics m on c.game_id = m.game_id
join games_metadata me on me.game_id = c.game_id
where price = 0
and positive_reviews > 50000
order by positive_reviews desc
;


------------------------------------------------------------------------------------------------------
--R8:
/*Hey, management wants to look at games that take a massive time commitment. 
Can you pull up the games where players spend an average of over 100 hours playing, 
but make sure they actually have enough people playing them so the data isn't skewed by like two guys? 
Oh, and only show me games released after January 1, 2020. Give me the name, the release date, 
and the average playtime, sorted from highest playtime to lowest.*/
------------------------------------------------------------------------------------------------------

select c.appid, name, release_date, avg_playtime_forever, estimated_owners
from games_core c
join games_metrics m on c.game_id = m.game_id
join games_metadata me on me.game_id = c.game_id

where avg_playtime_forever > 6000 
and release_date > '2020-1-1'
and estimated_owners > '0-0'
order by avg_playtime_forever desc


-------------------------------------------------------------------------------------------------
--R9
/*We need to audit our catalog to see which publishers dominate our library size. 
Pull the top 5 publishers who have released the highest number of total games in our database. 
Make sure you exclude any blank or null publisher names. 
Show me the publisher name and their total game count, ordered from the largest publisher down.*/
-------------------------------------------------------------------------------------------------

select top 5 publishers ,count(*) [games published]
from games_metadata
group by publishers
having publishers != '[]'
order by [games published] desc;
