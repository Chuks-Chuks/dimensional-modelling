CREATE TYPE actor_scd_type AS (
  quality_class quality_class,
  start_date INTEGER,
  end_year INTEGER,
  is_active BOOLEAN
);


WITH previous_year_scd AS (
  SELECT *
  FROM actors_history_scd
  WHERE end_year = 2020
),
  this_seaon_data AS (
    SELECT
      actor,
      actorid,
      quality_class,
      current_year,
      is_active
    FROM actors
    WHERE current_year = 2021
  ),
  unchanged_records AS (
    SELECT
      tsd.actor,
      tsd.actorid,
      tsd.quality_class,
      pys.start_date,
      tsd.current_year AS end_year,
      tsd.is_active
    FROM this_seaon_data tsd
    JOIN previous_year_scd pys ON pys.actorid = tsd.actorid
    WHERE pys.quality_class = tsd.quality_class AND pys.is_active = tsd.is_active
  ),
  changed_records AS (
      SELECT
        tsd2.actor,
        tsd2.actorid,
        unnest(ARRAY[
        ROW(
          tsd2.quality_class,
          tsd2.current_year,
          tsd2.current_year,
          tsd2.is_active
        )::actor_scd_type,
        ROW(
          pys2.quality_class,
          pys2.start_date,
          pys2.end_year,
          pys2.is_active
        )::actor_scd_type
        ]) AS records
      FROM this_seaon_data tsd2
      LEFT JOIN previous_year_scd pys2 ON pys2.actorid = tsd2.actorid
      WHERE (pys2.quality_class <> tsd2.quality_class AND pys2.is_active <> tsd2.is_active) OR pys2.actorid is NULL
  ),
  unnested_changed_records AS (
    SELECT
      actor,
      actorid,
      (records::actor_scd_type).quality_class,
      (records::actor_scd_type).start_date,
      (records::actor_scd_type).end_year,
      (records::actor_scd_type).is_active
    FROM changed_records
  ),
  new_records AS (
    SELECT
      tsd3.actor,
      tsd3.actorid,
      tsd3.quality_class,
      tsd3.current_year AS start_date,
      tsd3.current_year AS end_year,
      tsd3.is_active
    FROM this_seaon_data tsd3
    LEFT JOIN previous_year_scd pys3 ON pys3.actorid = tsd3.actorid
    WHERE pys3.actorid IS NULL
  )


SELECT *
FROM actors_history_scd

UNION ALL

SELECT *
FROM unchanged_records

UNION ALL

SELECT *
FROM unnested_changed_records

UNION ALL

SELECT *
FROM new_records

