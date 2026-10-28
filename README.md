# 🎮 Steam Video Game Market Analytics & BIGINER Data Pipeline

An end-to-end SQL data engineering and market analysis pipeline built in **SQL Server Management Studio (SSMS)**. This project transforms raw, uncleaned web-scraped video game data into a structured relational database to uncover key insights regarding pricing strategies, publisher dominance, and player engagement trends.

---

## 🏗️ Data Architecture & Pipeline Design

Real-world data is messy. This project mimics a professional production data pipeline, split into three distinct execution phases:

1. **Staging & Hygiene (`01_staging_and_cleaning.sql`)**: 
   - Ingests raw data into `steam_staging`.
   - Generates surrogate primary keys (`game_id`) using window functions (`ROW_NUMBER()`).
   - Audits data integrity and removes corrupted records (e.g., dropping rows with missing game names).
   - Utilizes `TRY_CAST` to proactively check for malformed data types before production transformation.

2. **Relational Normalization (`02_normalization_tables.sql`)**: 
   - Flattens the wide staging table into a clean, normalized relational model linked by `game_id` and `appid`:
     - **`games_core`**: Pricing, release dates, age ratings, and platform support (Windows, Mac, Linux).
     - **`games_metrics`**: Reviews, Metacritic scores, achievements, and playtime metrics.
     - **`games_metadata`**: Developers, publishers, genres, tags, and supported languages.
   - Applies string sanitization (`TRIM`) to eliminate whitespace artifacts that break joins.

3. **Business Intelligence & Auditing (`03_business_insights.sql`)**: 
   - Executes advanced analytical queries addressing real-world stakeholder questions.

---

## 📂 Repository Structure

```text
steam-analytics-pipeline/
│
├── sql/
│   ├── 01_staging_and_cleaning.sql
│   ├── 02_normalization_tables.sql
│   └── 03_business_insights.sql
│
└── README.md


## 📊 Key Analytical Insights

The project answers several complex business briefs through optimized SQL querying:

* **Pricing vs. Critical Acclaim:** Filtered premium titles ($30+) to evaluate top-rated games on Metacritic (e.g., identifying top performers like *The Witcher 3* and *Dark Souls II*).

* **Player Engagement Audit:** Tracked high-time-commitment games released post-2020, correctly handling Steam's minute-to-hour metric conversions (`> 6000` minutes) and auditing volume via estimated owners.

* **Publisher Market Share:** Grouped and filtered out formatting artifacts (`'[]'`) to find top-volume publishers dominating catalog sizes (e.g., *Big Fish Games*).

* **Data Anomaly Detection:** Identified multi-regional duplicate naming issues across distinct `appid`s (such as multiple entries for *Shadow of the Tomb Raider*).

---

## 🚀 How to Run

1. Open **SQL Server Management Studio (SSMS)**.
2. Execute the scripts in numerical order (`01` -> `02` -> `03`) against your local SQL Server instance.
3. Ensure your raw source table (`steam_2025_RawData`) is loaded before executing Phase 1.

---

## 🔮 Future Improvements & Scalability

This pipeline was built as an exploratory and analytical baseline in SQL Server Management Studio. For production deployment at scale, key optimizations would include:

* **Automated Data Quality & Error Handling:** Transitioning from row-deletion to a dedicated Dead Letter Queue / Error Audit table to retain corrupt records for ingestion monitoring.
* **Pipeline Idempotency:** Implementing `IF OBJECT_ID ... DROP TABLE` or `TRUNCATE` workflows to ensure execution scripts are fully re-runnable without manual cleanup.
* **Indexing & Performance Tuning:** Adding clustered/non-clustered indexes on surrogate keys (`game_id`, `appid`) to optimize query execution plans across multi-table joins.
* **Normalized Array Parsing:** Utilizing SQL JSON parsing tools or cross-apply logic to unpack list-string fields (like `genres` and `developers`) into formal bridge tables.
