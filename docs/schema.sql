CREATE TABLE source (
    source_id  TEXT PRIMARY KEY,
    title      TEXT NOT NULL,
    publisher  TEXT,
    year       SMALLINT,
    url        TEXT,
    licence    TEXT,
    accessed   DATE
);

CREATE TABLE crop (
    crop_id         TEXT PRIMARY KEY,
    name_en         TEXT,
    scientific_name TEXT,
    spam_code       TEXT UNIQUE,
    ecocrop_code    TEXT,
    is_food_staple  BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE food (
    food_id   TEXT PRIMARY KEY,
    name_en   TEXT,
    name_fr   TEXT,
    source_id TEXT REFERENCES source(source_id),
    basis     TEXT NOT NULL DEFAULT 'per 100 g edible portion'
);

CREATE TABLE crop_food (
    crop_id   TEXT REFERENCES crop(crop_id) ON DELETE CASCADE,
    food_id   TEXT REFERENCES food(food_id) ON DELETE CASCADE,
    rationale TEXT,
    PRIMARY KEY (crop_id, food_id)
);

CREATE TABLE nutrient (
    nutrient_id TEXT PRIMARY KEY,          -- INFOODS tagname, e.g. 'FE', 'ENERC_kcal'
    name_en     TEXT,
    unit        TEXT
);

CREATE TABLE food_nutrient (
    food_id     TEXT REFERENCES food(food_id) ON DELETE CASCADE,
    nutrient_id TEXT REFERENCES nutrient(nutrient_id),
    value       DOUBLE PRECISION,
    flag        TEXT NOT NULL CHECK (flag IN ('value', 'estimated', 'trace', 'missing')),
    source_id   TEXT REFERENCES source(source_id),
    PRIMARY KEY (food_id, nutrient_id),
    CHECK (flag IN ('trace', 'missing') OR value IS NOT NULL)   -- optional: drop if it blocks your load
);

CREATE TABLE crop_requirement (
    crop_id   TEXT REFERENCES crop(crop_id) ON DELETE CASCADE,
    variable  TEXT,                        -- 'temperature', 'rainfall', 'ph', 'cycle'
    abs_min   DOUBLE PRECISION,
    opt_min   DOUBLE PRECISION,
    opt_max   DOUBLE PRECISION,
    abs_max   DOUBLE PRECISION,
    unit      TEXT,
    source_id TEXT REFERENCES source(source_id),
    PRIMARY KEY (crop_id, variable),
    CHECK (abs_min <= opt_min AND opt_min <= opt_max AND opt_max <= abs_max)  -- NULLs pass
);

CREATE TABLE crop_soil_class (
    crop_id   TEXT REFERENCES crop(crop_id) ON DELETE CASCADE,
    property  TEXT,                        -- 'salinity', 'texture', 'drainage'
    optimal   TEXT,
    absolute  TEXT,
    source_id TEXT REFERENCES source(source_id),
    PRIMARY KEY (crop_id, property)
);

-- Indexes for foreign keys not covered by a primary key's leading column
CREATE INDEX ON food (source_id);
CREATE INDEX ON crop_food (food_id);
CREATE INDEX ON food_nutrient (nutrient_id);
CREATE INDEX ON food_nutrient (source_id);
CREATE INDEX ON crop_requirement (source_id);
CREATE INDEX ON crop_soil_class (source_id);

CREATE OR REPLACE VIEW v_crop_nutrition AS
SELECT c.crop_id, c.name_en AS crop, n.nutrient_id, n.name_en AS nutrient,
       n.unit, fn.value, fn.flag
FROM crop c
JOIN crop_food cf     ON cf.crop_id = c.crop_id
JOIN food_nutrient fn ON fn.food_id = cf.food_id
JOIN nutrient n       ON n.nutrient_id = fn.nutrient_id
WHERE fn.flag IN ('value', 'estimated');
