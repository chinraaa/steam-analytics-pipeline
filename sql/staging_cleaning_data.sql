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