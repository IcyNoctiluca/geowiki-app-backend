DROP DATABASE `geowiki`;
CREATE DATABASE `geowiki`;
USE `geowiki`;


SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS `continent`;
SET FOREIGN_KEY_CHECKS=1;
CREATE TABLE `continent`
  (
     `id`             INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL,
     `name`           VARCHAR(255) NOT NULL,
     `population`     INTEGER NULL,
     `area`           INTEGER NULL,
     `stamp_created`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
     `stamp_modified` TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
 );


 SET FOREIGN_KEY_CHECKS=0;
 DROP TABLE IF EXISTS `country`;
 SET FOREIGN_KEY_CHECKS=1;
 CREATE TABLE `country`
   (
      `id`             INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL,
      `cont_id`        INTEGER NOT NULL,
      `name`           VARCHAR(255) NOT NULL,
      `population`     INTEGER NULL,
      `area`           INTEGER NULL,
      `no_hospitals`   INTEGER NULL,
      `no_parks`       INTEGER NULL,
      `no_rivers`      INTEGER NULL,
      `no_schools`     INTEGER NULL,
      `stamp_created`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `stamp_modified` TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (cont_id)
      REFERENCES continent (id)
      ON DELETE CASCADE
  );


SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS city;
SET FOREIGN_KEY_CHECKS=1;
CREATE TABLE `city`
(
   `id`             INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL,
   `country_id`     INTEGER NOT NULL,
   `name`           VARCHAR(255) NOT NULL,
   `population`     INTEGER NULL,
   `area`           INTEGER NULL,
   `no_roads`       INTEGER NULL,
   `no_trees`       INTEGER NULL,
   `no_shops`       INTEGER NULL,
   `no_schools`     INTEGER NULL,
   `stamp_created`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `stamp_modified` TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   FOREIGN KEY (country_id)
   REFERENCES country (id)
   ON DELETE CASCADE
);



DROP TRIGGER IF EXISTS continent_update_check;
DELIMITER $
CREATE TRIGGER continent_update_check
BEFORE UPDATE ON continent FOR EACH ROW
BEGIN

    CALL sp_validate_continent_area(NEW.id, NEW.area);
    CALL sp_validate_continent_population(NEW.id, NEW.population);

END$
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_validate_continent_population;
DELIMITER $$
CREATE PROCEDURE sp_validate_continent_population(
   IN _id INTEGER, IN _population INTEGER
)
BEGIN

   DECLARE countries_population INTEGER;
   SET countries_population = (SELECT IFNULL(SUM(population), 0) FROM country WHERE cont_id = _id);

   IF (_population < countries_population) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'check constraint population failed';
   END IF;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_validate_continent_area;
DELIMITER $$
CREATE PROCEDURE sp_validate_continent_area(
   IN _id INTEGER, IN _area INTEGER
)
BEGIN

    DECLARE countries_area INTEGER;
    SET countries_area = (SELECT IFNULL(SUM(area), 0) FROM country WHERE cont_id = _id);

    IF (_area < countries_area) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'check constraint area failed';
    END IF;

END $$
DELIMITER ;



DROP TRIGGER IF EXISTS country_insert_check;
DELIMITER $
CREATE TRIGGER country_insert_check
BEFORE INSERT ON country FOR EACH ROW
BEGIN

    CALL sp_validate_country_area(NEW.id, NEW.cont_id, NEW.area);
    CALL sp_validate_country_population(NEW.id, NEW.cont_id, NEW.population);
    CALL sp_validate_country_schools(NEW.id, NEW.no_schools);


END$
DELIMITER ;


DROP TRIGGER IF EXISTS country_update_check;
DELIMITER $
CREATE TRIGGER country_update_check
BEFORE UPDATE ON country FOR EACH ROW
BEGIN

    CALL sp_validate_country_area(NEW.id, NEW.cont_id, NEW.area);
    CALL sp_validate_country_population(NEW.id, NEW.cont_id, NEW.population);
    CALL sp_validate_country_schools(NEW.id, NEW.no_schools);

END$
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_validate_country_population;
DELIMITER $$
CREATE PROCEDURE sp_validate_country_population(
   IN _id INTEGER, IN _cont_id INTEGER, IN _population INTEGER
)
BEGIN

    DECLARE continent_population INTEGER;
    DECLARE cities_population INTEGER;
    DECLARE potential_cumulative_countries_population INTEGER;

    SET potential_cumulative_countries_population = (SELECT IFNULL(SUM(population), 0) + _population FROM country WHERE cont_id = _cont_id AND id != _id);
    SET continent_population = (SELECT IFNULL(SUM(population), 0) FROM continent WHERE id = _cont_id);
    SET cities_population = (SELECT IFNULL(SUM(population), 0) FROM city WHERE country_id = _id);

    IF (potential_cumulative_countries_population > continent_population) OR (cities_population > _population) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'check constraint population failed';
    END IF;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_validate_country_area;
DELIMITER $$
CREATE PROCEDURE sp_validate_country_area(
   IN _id INTEGER, IN _cont_id INTEGER, IN _area INTEGER
)
BEGIN

    DECLARE continent_area INTEGER;
    DECLARE cities_area INTEGER;
    DECLARE potential_cumulative_countries_area INTEGER;

    SET potential_cumulative_countries_area = (SELECT IFNULL(SUM(area), 0) + _area FROM country WHERE cont_id = _cont_id AND id != _id);
    SET continent_area = (SELECT IFNULL(SUM(area), 0) FROM continent WHERE id = _cont_id);
    SET cities_area = (SELECT IFNULL(SUM(area), 0) FROM city WHERE country_id = _id);

    IF (potential_cumulative_countries_area > continent_area) OR (cities_area > _area) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'check constraint area failed';
    END IF;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_validate_country_schools;
DELIMITER $$
CREATE PROCEDURE sp_validate_country_schools(
   IN _id INTEGER, IN _no_schools INTEGER
)
BEGIN

    DECLARE cities_school INTEGER;

    SET cities_school = (SELECT IFNULL(SUM(no_schools), 0) FROM city WHERE country_id = _id);

    IF (_no_schools < cities_school) THEN
         SIGNAL SQLSTATE '45000'
         SET MESSAGE_TEXT = 'check constraint schools failed';
    END IF;

END $$
DELIMITER ;




DROP TRIGGER IF EXISTS city_insert_check;
DELIMITER $
CREATE TRIGGER city_insert_check
BEFORE INSERT ON city FOR EACH ROW
BEGIN

    CALL sp_validate_city_area(NEW.id, NEW.country_id, NEW.area);
    CALL sp_validate_city_population(NEW.id, NEW.country_id, NEW.population);
    CALL sp_validate_city_schools(NEW.id, NEW.country_id, NEW.no_schools);

END$
DELIMITER ;


DROP TRIGGER IF EXISTS city_update_check;
DELIMITER $
CREATE TRIGGER city_update_check
BEFORE UPDATE ON city FOR EACH ROW
BEGIN

    CALL sp_validate_city_area(NEW.id, NEW.country_id, NEW.area);
    CALL sp_validate_city_population(NEW.id, NEW.country_id, NEW.population);
    CALL sp_validate_city_schools(NEW.id, NEW.country_id, NEW.no_schools);

END$
DELIMITER ;




DROP PROCEDURE IF EXISTS sp_validate_city_population;
DELIMITER $$
CREATE PROCEDURE sp_validate_city_population(
   IN _id INTEGER, IN _country_id INTEGER, IN _population INTEGER
)
BEGIN

    DECLARE country_population INTEGER;
    DECLARE potential_cumulative_cities_population INTEGER;

    SET country_population = (SELECT IFNULL(SUM(population), 0) FROM country WHERE id = _country_id);

    SET potential_cumulative_cities_population = (SELECT IFNULL(SUM(population), 0) + _population FROM city WHERE country_id = _country_id AND id != _id);

    IF (potential_cumulative_cities_population > country_population) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'check constraint population failed';

    END IF;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_validate_city_area;
DELIMITER $$
CREATE PROCEDURE sp_validate_city_area(
   IN _id INTEGER, IN _country_id INTEGER, IN _area INTEGER
)
BEGIN

    DECLARE country_area INTEGER;
    DECLARE potential_cumulative_cities_area INTEGER;

    SET country_area = (SELECT IFNULL(SUM(area), 0) FROM country WHERE id = _country_id);

    SET potential_cumulative_cities_area = (SELECT IFNULL(SUM(area), 0) + _area FROM city WHERE country_id = _country_id AND id != _id);

    IF (potential_cumulative_cities_area > country_area) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'check constraint area failed';
    END IF;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS sp_validate_city_schools;
DELIMITER $$
CREATE PROCEDURE sp_validate_city_schools(
   IN _id INTEGER, IN _country_id INTEGER, IN _no_schools INTEGER
)
BEGIN

    DECLARE country_schools INTEGER;
    DECLARE potential_cumulative_cities_schools INTEGER;

    SET country_schools = (SELECT IFNULL(SUM(no_schools), 0) FROM country WHERE id = _country_id);

    SET potential_cumulative_cities_schools = (SELECT IFNULL(SUM(no_schools), 0) + _no_schools FROM city WHERE country_id = _country_id AND id != _id);

    IF (potential_cumulative_cities_schools > country_schools) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'check constraint schools failed';
    END IF;

END $$
DELIMITER ;






INSERT INTO continent (name, population, area) VALUES ('ASIA', 4463000, 44580000);
SET @cont_id = (SELECT MAX(id) FROM continent);

INSERT INTO country (cont_id, name, population, area, no_schools) VALUES (@cont_id, 'CHINA', 1400050, 9596961, 1000000);
INSERT INTO country (cont_id, name, population, area, no_schools) VALUES (@cont_id, 'JAPAN', 125000, 377975, 20000000);
SET @country_id = (SELECT MAX(id) FROM country);

INSERT INTO city (country_id, name, population, area, no_schools) VALUES (@country_id, 'TOKYO', 13929, 2194, 2671);
INSERT INTO city (country_id, name, population, area, no_schools) VALUES (@country_id, 'KYOTO', 1475, 827, 1000);
