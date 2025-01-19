CREATE TABLE actors_history_scd (
    actor TEXT,
    actorid TEXT,
    quality_class quality_class,
    start_date INTEGER,
    end_year INTEGER,
    is_active BOOLEAN NOT NULL,
    PRIMARY KEY (actorid, end_year)
);
