
INSERT INTO actors_history_scd
WITH with_previous_years AS (
    SELECT
      actor,
      actorid,
      quality_class,
      is_active,
      lag(quality_class, 1) OVER (PARTITION BY actorid ORDER BY current_year) AS previous_quality_class,
      lag(is_active, 1) OVER (PARTITION BY actorid ORDER BY current_year) AS previous_is_active,
      current_year
    FROM actors
    WHERE current_year <= 2020
), with_indicators AS (
  SELECT
    *,
    CASE
      WHEN quality_class <> previous_quality_class THEN 1
      WHEN is_active <> previous_is_active THEN 1
      ELSE 0
    END AS change_indicator
  FROM with_previous_years
),
  with_streaks AS (
    SELECT
      *,
      sum(change_indicator) OVER (PARTITION BY actorid ORDER BY current_year) AS streaks
    FROM with_indicators
  )


SELECT
  actor,
  actorid,
  quality_class,
  min(current_year) AS start_year,
  max(current_year) AS end_year,
  is_active
FROM with_streaks
GROUP BY actor, actorid, quality_class, is_active, streaks
ORDER BY 1, streaks;

SELECT * from actors_history_scd;