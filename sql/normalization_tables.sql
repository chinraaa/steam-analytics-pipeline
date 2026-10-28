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