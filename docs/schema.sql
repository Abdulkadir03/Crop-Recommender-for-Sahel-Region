
PRAGMA foreign_keys = ON;

CREATE TABLE source (
    source_id TEXT PRIMARY KEY, title TEXT NOT NULL, publisher TEXT, year INTEGER,
    url TEXT, licence TEXT, accessed TEXT);

CREATE TABLE crop (
    crop_id TEXT PRIMARY KEY, name_en TEXT, scientific_name TEXT, spam_code TEXT,
    ecocrop_code TEXT, is_food_staple INTEGER);

CREATE TABLE food (
    food_id TEXT PRIMARY KEY, name_en TEXT, name_fr TEXT,
    source_id TEXT REFERENCES source(source_id), basis TEXT DEFAULT 'per 100 g edible portion');

CREATE TABLE crop_food (
    crop_id TEXT REFERENCES crop(crop_id), food_id TEXT REFERENCES food(food_id),
    rationale TEXT, PRIMARY KEY (crop_id, food_id));

CREATE TABLE nutrient (
    nutrient_id TEXT PRIMARY KEY,            -- INFOODS tagname, e.g. 'FE', 'ENERC_kcal'
    name_en TEXT, unit TEXT);

CREATE TABLE food_nutrient (
    food_id TEXT REFERENCES food(food_id), nutrient_id TEXT REFERENCES nutrient(nutrient_id),
    value REAL,
    flag TEXT CHECK (flag IN ('value', 'estimated', 'trace', 'missing')),
    source_id TEXT REFERENCES source(source_id),
    PRIMARY KEY (food_id, nutrient_id));

CREATE TABLE crop_requirement (
    crop_id TEXT REFERENCES crop(crop_id), variable TEXT,   -- 'temperature', 'rainfall', 'ph', 'cycle'
    abs_min REAL, opt_min REAL, opt_max REAL, abs_max REAL, unit TEXT,
    source_id TEXT REFERENCES source(source_id), PRIMARY KEY (crop_id, variable));

CREATE TABLE crop_soil_class (
    crop_id TEXT REFERENCES crop(crop_id), property TEXT,   -- 'salinity', 'texture', 'drainage'
    optimal TEXT, absolute TEXT, source_id TEXT REFERENCES source(source_id),
    PRIMARY KEY (crop_id, property));

CREATE VIEW v_crop_nutrition AS
SELECT c.crop_id, c.name_en AS crop, n.nutrient_id, n.name_en AS nutrient, n.unit, fn.value, fn.flag
FROM crop c JOIN crop_food cf ON cf.crop_id = c.crop_id
JOIN food_nutrient fn ON fn.food_id = cf.food_id
JOIN nutrient n ON n.nutrient_id = fn.nutrient_id
WHERE fn.flag IN ('value', 'estimated');
