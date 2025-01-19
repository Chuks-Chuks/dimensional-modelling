DO $$
DECLARE
    start_year INT := 1970;
    end_year INT := 2021;
    curr_year INT;
BEGIN
    FOR curr_year IN start_year..end_year LOOP

        INSERT INTO actors
        WITH previous_year AS (
            SELECT *
            FROM actors
            WHERE current_year = curr_year - 1
        ),
        current_year AS (
            SELECT *
            FROM actor_films
            WHERE year = curr_year
        ),
        average_rating AS (
            SELECT actor, actorid, AVG(rating) AS rating
            FROM current_year
            GROUP BY actor, actorid
        )
        SELECT
            COALESCE(p.actor, c.actor) AS actor,
            COALESCE(p.actorid, c.actorid) AS actorid,
            CASE
                WHEN p.films IS NULL THEN
                    array_agg(ROW(
                        c.film,
                        c.votes,
                        c.rating,
                        c.year,
                        c.filmid
                    )::films)
                WHEN c.year IS NOT NULL THEN
                    p.films || array_agg(ROW(
                        c.film,
                        c.votes,
                        c.rating,
                        c.year,
                        c.filmid
                    )::films)
                ELSE p.films
            END AS films,
            CASE
                WHEN c.year IS NOT NULL
                THEN
                    CASE
                        WHEN ar.rating > 8 THEN 'star'
                        WHEN ar.rating > 7 AND ar.rating <=8 THEN 'good'
                        WHEN ar.rating > 6 AND ar.rating <=7 THEN 'average'
                        ELSE 'bad'
                    END::quality_class
                ELSE p.quality_class
            END AS quality_class,
            COALESCE(c.year, p.current_year + 1) AS current_year,
            CASE
                WHEN c.year IS NOT NULL THEN TRUE
                ELSE FALSE
            END AS is_active

        FROM current_year c
        FULL OUTER JOIN previous_year p ON p.actorid = c.actorid
        FULL OUTER JOIN average_rating ar ON ar.actorid = COALESCE(p.actorid, c.actorid)
        GROUP BY COALESCE(p.actor, c.actor), COALESCE(p.actorid, c.actorid), p.films,p.quality_class, p.current_year, c.year, ar.rating;
    END LOOP;
END $$;

