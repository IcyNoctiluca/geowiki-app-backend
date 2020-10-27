
DROP PROCEDURE IF EXISTS sp_insert_continent;
DELIMITER $$
CREATE PROCEDURE sp_insert_continent(
   IN _name VARCHAR(127), OUT _id INTEGER
)
BEGIN

   INSERT INTO continent (`name`)
   VALUES (_name);

   SET _id = LAST_INSERT_ID();

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_insert_country;
DELIMITER $$
CREATE PROCEDURE sp_insert_country(
   IN _name VARCHAR(127), IN _cont_id INTEGER, OUT _id INTEGER
)
BEGIN

   INSERT INTO country (`name`,`cont_id`)
   VALUES (_name, _cont_id);

   SET _id = LAST_INSERT_ID();

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_insert_city;
DELIMITER $$
CREATE PROCEDURE sp_insert_city(
   IN _name VARCHAR(127), IN _country_id INTEGER, OUT _id INTEGER
)
BEGIN

   INSERT INTO city (`name`, `country_id`)
   VALUES (_name, _country_id);

   SET _id = LAST_INSERT_ID();

END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS sp_update_continent_population;
DELIMITER $$
CREATE PROCEDURE sp_update_continent_population(
   IN _id INTEGER, IN _population INTEGER
)
BEGIN

   DECLARE countries_population INTEGER;
   SET countries_population = (SELECT IFNULL(SUM(population), 0) FROM country WHERE cont_id = _id);

   IF (_population < countries_population) THEN
        SELECT CONCAT('failed because invalid value for population. Must be greater than ', countries_population);
   ELSE

        UPDATE continent
        SET population = _population
        WHERE id = _id;

        SELECT CONCAT('successful information inserted for population of continent ', _id);

   END IF;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_update_continent_area;
DELIMITER $$
CREATE PROCEDURE sp_update_continent_area(
   IN _id INTEGER, IN _area INTEGER
)
BEGIN

    DECLARE countries_area INTEGER;
    SET countries_area = (SELECT IFNULL(SUM(area), 0) FROM country WHERE cont_id = _id);

    IF (_area < countries_area) THEN
         SELECT CONCAT('failed because invalid value for area. Must be greater than ', countries_area);
    ELSE

         UPDATE continent
         SET area = _area
         WHERE id = _id;

         SELECT CONCAT('successful information inserted for area of continent ', _id);

    END IF;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_update_country_population;
DELIMITER $$
CREATE PROCEDURE sp_update_country_population(
   IN _id INTEGER, IN _population INTEGER
)
BEGIN

    DECLARE _cont_id INTEGER;
    DECLARE continent_population INTEGER;
    DECLARE cities_population INTEGER;

    SET _cont_id = (SELECT cont_id FROM country WHERE id = _id);
    SET continent_population = (SELECT population FROM continent WHERE id = _cont_id);
    SET cities_population = (SELECT IFNULL(SUM(population), 0) FROM city WHERE country_id = _id);

    IF (_population > continent_population) OR (cities_population > _population) THEN
         SELECT CONCAT('failed because invalid value for population. Must be greater than ', cities_population, ' and smaller than ', continent_population);
    ELSE

         UPDATE country
         SET population = _population
         WHERE id = _id;

         SELECT CONCAT('successful information inserted for population of country ', _id);

    END IF;

END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS sp_update_country_area;
DELIMITER $$
CREATE PROCEDURE sp_update_country_area(
   IN _id INTEGER, IN _area INTEGER
)
BEGIN

    DECLARE _cont_id INTEGER;
    DECLARE continent_area INTEGER;
    DECLARE cities_area INTEGER;

    SET _cont_id = (SELECT cont_id FROM country WHERE id = _id);
    SET continent_area = (SELECT area FROM continent WHERE id = _cont_id);
    SET cities_area = (SELECT IFNULL(SUM(area), 0) FROM city WHERE country_id = _id);

    IF (_area > continent_area) OR (cities_area > _area ) THEN
         SELECT CONCAT('failed because invalid value for area. Must be greater than ', cities_area, ' and smaller than ', continent_area);
    ELSE

         UPDATE country
         SET area = _area
         WHERE id = _id;

         SELECT CONCAT('successful information inserted for area of country ', _id);

    END IF;

END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS sp_update_country_schools;
DELIMITER $$
CREATE PROCEDURE sp_update_country_schools(
   IN _id INTEGER, IN _no_schools INTEGER
)
BEGIN

    DECLARE cities_school INTEGER;

    SET cities_school = (SELECT IFNULL(SUM(no_schools), 0) FROM city WHERE country_id = _id);

    IF (_no_schools < cities_school) THEN
         SELECT CONCAT('failed because invalid value for schools. Must be greater than ', cities_school);
    ELSE

         UPDATE country
         SET no_schools = _no_schools
         WHERE id = _id;

         SELECT CONCAT('successful information inserted for schools of country ', _id);

    END IF;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_update_city_population;
DELIMITER $$
CREATE PROCEDURE sp_update_city_population(
   IN _id INTEGER, IN _population INTEGER
)
BEGIN

    DECLARE _country_id INTEGER;
    DECLARE country_population INTEGER;
    DECLARE potential_cumulative_cities_population INTEGER;

    SET _country_id = (SELECT country_id FROM city WHERE id = _id);
    SET country_population = (SELECT population FROM country WHERE id = _country_id);

    SET potential_cumulative_cities_population = (SELECT IFNULL(SUM(population), 0) + _population FROM city WHERE country_id = _country_id AND id != _id);

    IF (potential_cumulative_cities_population > country_population) THEN
         SELECT CONCAT('failed because invalid value for population. Must be smaller than ', country_population);
    ELSE

         UPDATE city
         SET population = _population
         WHERE id = _id;

         SELECT CONCAT('successful information inserted for population of city ', _id);

    END IF;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_update_city_area;
DELIMITER $$
CREATE PROCEDURE sp_update_city_area(
   IN _id INTEGER, IN _area INTEGER
)
BEGIN

    DECLARE _country_id INTEGER;
    DECLARE country_area INTEGER;
    DECLARE potential_cumulative_cities_area INTEGER;

    SET _country_id = (SELECT country_id FROM city WHERE id = _id);
    SET country_area = (SELECT area FROM country WHERE id = _country_id);

    SET potential_cumulative_cities_area = (SELECT IFNULL(SUM(area), 0) + _area FROM city WHERE country_id = _country_id AND id != _id);

    IF (potential_cumulative_cities_area > country_area) THEN
         SELECT CONCAT('failed because invalid value for area. Must be smaller than ', country_area);
    ELSE

         UPDATE city
         SET area = _area
         WHERE id = _id;

         SELECT CONCAT('successful information inserted for area of city ', _id);

    END IF;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_update_city_schools;
DELIMITER $$
CREATE PROCEDURE sp_update_city_schools(
   IN _id INTEGER, IN _no_schools INTEGER
)
BEGIN

    DECLARE _country_id INTEGER;
    DECLARE country_schools INTEGER;
    DECLARE potential_cumulative_cities_schools INTEGER;

    SET _country_id = (SELECT country_id FROM city WHERE id = _id);
    SET country_schools = (SELECT no_schools FROM country WHERE id = _country_id);

    SET potential_cumulative_cities_schools = (SELECT IFNULL(SUM(no_schools), 0) + _no_schools FROM city WHERE country_id = _country_id AND id != _id);

    IF (potential_cumulative_cities_schools > country_schools) THEN
         SELECT CONCAT('failed because invalid value for schools. Must be smaller than ', potential_cumulative_cities_schools - country_schools);
    ELSE

         UPDATE city
         SET no_schools = _no_schools
         WHERE id = _id;

         SELECT CONCAT('successful information inserted for schools of city ', _id);

    END IF;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_update_city_shops;
DELIMITER $$
CREATE PROCEDURE sp_update_city_shops(
   IN _id INTEGER, IN _shops INTEGER
)
BEGIN

   UPDATE city
   SET no_shops = _shops
   WHERE id = _id;

END $$
DELIMITER ;







DROP PROCEDURE IF EXISTS sp_update_continent_name;
DELIMITER $$
CREATE PROCEDURE sp_update_continent_name(
   IN _id INTEGER, IN _name INTEGER
)
BEGIN

   UPDATE continent
   SET name = _name
   WHERE id = _id;

END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_update_country_name;
DELIMITER $$
CREATE PROCEDURE sp_update_country_name(
   IN _id INTEGER, IN _name INTEGER
)
BEGIN

   UPDATE country
   SET name = _name
   WHERE id = _id;

END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_update_city_name;
DELIMITER $$
CREATE PROCEDURE sp_update_city_name(
   IN _id INTEGER, IN _name INTEGER
)
BEGIN

   UPDATE city
   SET name = _name
   WHERE id = _id;

END $$
DELIMITER ;
