CREATE TABLE IF NOT EXISTS electric_vehicles
(
    vehicle_id integer NOT NULL DEFAULT nextval('electric_vehicles_vehicle_id_seq'::regclass),
    manufacturer text COLLATE pg_catalog."default",
    model text COLLATE pg_catalog."default",
    year integer,
    battery_type text COLLATE pg_catalog."default",
    battery_capacity_kwh double precision,
    range_km integer,
    charging_type text COLLATE pg_catalog."default",
    charge_time_hr double precision,
    price_usd numeric(10,2),
    CONSTRAINT electric_vehicles_pkey PRIMARY KEY (vehicle_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS electric_vehicles
    OWNER to postgres;
--Basic Query
--1
SELECT manufacturer, model, avg(price_usd) from electric_vehicles
Group By  manufacturer, model
--2
WITH top_models AS (
  SELECT 
    manufacturer, model, MAX(price_usd) AS max_price
  FROM electric_vehicles
  GROUP BY manufacturer, model
)
SELECT 
  e.manufacturer,
  e.model,
  e.year,
  e.battery_type,
  e.range_km,
  e.price_usd
FROM electric_vehicles e
JOIN top_models t ON e.manufacturer = t.manufacturer AND e.model = t.model AND e.price_usd = t.max_price
ORDER BY e.price_usd DESC;
--3
SELECT 
  manufacturer,
  model,
  ROUND(AVG(price_usd), 2) AS avg_price,
  ROUND(AVG(battery_capacity_kwh)::numeric, 1) AS avg_capacity,
  CASE 
    WHEN AVG(price_usd) < 40000 THEN 'Ekonomik'
    WHEN AVG(price_usd) BETWEEN 40000 AND 70000 THEN 'Orta Segment'
    ELSE 'Premium'
  END AS price_segment
FROM electric_vehicles
GROUP BY manufacturer, model
ORDER BY avg_price DESC;

--Advanced Query
--1
SELECT
  manufacturer,
  model,
  range_km,
  price_usd,
CASE WHEN range_km > 400 THEN ROUND(price_usd * 0.88, 2)
ELSE ROUND(price_usd * 0.97, 2) END AS km_bazli_indirim
FROM electric_vehicles;
--2
WITH affordable_long_range_cars AS (
  SELECT
    manufacturer,
    model,
    range_km,
    price_usd
  FROM
    electric_vehicles
  WHERE
    price_usd < 56450 AND range_km > 400
)
SELECT
  manufacturer,
  model,
  range_km,
  price_usd,
  ROUND(price_usd * 0.95, 2) AS efficiency_discount_price 
FROM
  affordable_long_range_cars 
ORDER BY
  price_usd DESC;
 --3
 WITH base_vehicles AS (
  SELECT
    manufacturer,
    model,
    range_km,
    price_usd
  FROM
    electric_vehicles
  WHERE
    price_usd < 120000
)
SELECT
  manufacturer,
  model,
  range_km,
  price_usd,
  CASE
    WHEN range_km > 300 THEN ROUND(price_usd * 1.35, 2) 
    ELSE ROUND(price_usd * 1.65, 2)                   
  END AS zamli_fiyat
FROM
  base_vehicles
ORDER BY
  manufacturer;
--4
SELECT
  manufacturer,
  model,
  battery_type,
  price_usd,
  CASE
    WHEN battery_type = 'Lithium-Ion' THEN ROUND(price_usd * 1.24, 2) 
    ELSE ROUND(price_usd * 1.12, 2)                                
  END AS zamli_fiyat
FROM
  electric_vehicles
ORDER BY
  battery_type, manufacturer;
--5
WITH manufacturer_avg_price AS (
  SELECT
    manufacturer,
    ROUND(AVG(price_usd), 2) AS avg_manufacturer_price
  FROM
    electric_vehicles
  GROUP BY
    manufacturer
)
SELECT
  ev.manufacturer,
  ev.model,
  ev.price_usd,
  map.avg_manufacturer_price 
FROM
  electric_vehicles AS ev
JOIN
  manufacturer_avg_price AS map 
  ON ev.manufacturer = map.manufacturer 
WHERE
  ev.price_usd > map.avg_manufacturer_price 
ORDER BY
  ev.manufacturer, ev.price_usd DESC;

Select model,year from electric_vehicles
where year  between 2021 and 2024 
  