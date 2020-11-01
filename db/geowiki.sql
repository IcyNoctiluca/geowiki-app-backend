DROP DATABASE IF EXISTS`geowiki`;
CREATE DATABASE `geowiki`;
USE `geowiki`;


CREATE USER `writer_user`@`localhost` IDENTIFIED BY 'canary';
GRANT SELECT, INSERT, UPDATE, DELETE ON `geowiki`.* TO `writer_user`@`localhost`;


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
INSERT INTO continent (name, population, area) VALUES ('AUSTRALIA', 39000, 8600000);
INSERT INTO continent (name, population, area) VALUES ('EUROPE', 741400, 10180000);
INSERT INTO continent (name, population, area) VALUES ('AFRICA', 1216000, 30370000);
INSERT INTO continent (name, population, area) VALUES ('N AMERICA', 579000, 24710000);
INSERT INTO continent (name, population, area) VALUES ('S AMERICA', 422500, 17840000);
INSERT INTO continent (name, population, area) VALUES ('ANTARCTICA', 1, 14200000);

INSERT INTO `country` (`id`, `cont_id`, `name`, `population`, `area`, `no_hospitals`, `no_parks`, `no_rivers`, `no_schools`, `stamp_created`, `stamp_modified`) VALUES
(1, 1, 'CHINA', 1400050, 9596961, NULL, NULL, NULL, 1000000, '2020-11-01 10:24:25', '2020-11-01 10:24:25'),
(2, 1, 'JAPAN', 125000, 377975, NULL, NULL, NULL, 20000000, '2020-11-01 10:24:25', '2020-11-01 10:24:25'),
(3, 7, 'Dominican Republic', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:33', '2020-11-01 10:24:33'),
(4, 7, 'Norway', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:36', '2020-11-01 10:24:36'),
(5, 4, 'Belgium', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:37', '2020-11-01 10:24:37'),
(6, 7, 'Bolivia', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:38', '2020-11-01 10:24:38'),
(7, 2, 'Gabon', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:40', '2020-11-01 10:24:40'),
(8, 6, 'South Africa', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:43', '2020-11-01 10:24:43'),
(9, 4, 'Argentina', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:44', '2020-11-01 10:24:44'),
(10, 2, 'Wallis and Futuna', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:45', '2020-11-01 10:24:45'),
(11, 6, 'Turks and Caicos Islands', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:46', '2020-11-01 10:24:46'),
(12, 4, 'Germany', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:47', '2020-11-01 10:24:47'),
(13, 2, 'Iraq', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:49', '2020-11-01 10:24:49'),
(14, 1, 'Algeria', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:55', '2020-11-01 10:24:55'),
(15, 6, 'Azerbaijan', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:57', '2020-11-01 10:24:57'),
(16, 3, 'Belgium', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:59', '2020-11-01 10:24:59'),
(17, 6, 'Georgia', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:25:02', '2020-11-01 10:25:02'),
(18, 7, 'Cote d\'Ivoire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:25:03', '2020-11-01 10:25:03'),
(19, 3, 'Nigeria', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:25:05', '2020-11-01 10:25:05'),
(20, 6, 'Cook Islands', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:25:06', '2020-11-01 10:25:06'),
(21, 1, 'Hong Kong', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:16', '2020-11-01 10:26:16'),
(22, 3, 'Bahamas', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:17', '2020-11-01 10:26:17'),
(23, 6, 'Afghanistan', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:20', '2020-11-01 10:26:20'),
(24, 2, 'Djibouti', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:24', '2020-11-01 10:26:24'),
(25, 6, 'Norway', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:25', '2020-11-01 10:26:25'),
(26, 5, 'Israel', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:27', '2020-11-01 10:26:27'),
(27, 3, 'Turkey', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:30', '2020-11-01 10:26:30'),
(28, 6, 'Israel', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:31', '2020-11-01 10:26:31'),
(29, 4, 'Guadeloupe', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:32', '2020-11-01 10:26:32'),
(30, 2, 'Hong Kong', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:36', '2020-11-01 10:26:36'),
(31, 3, 'Montenegro', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:37', '2020-11-01 10:26:37'),
(32, 4, 'Bulgaria', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:38', '2020-11-01 10:26:38'),
(33, 2, 'Oman', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:42', '2020-11-01 10:26:42'),
(34, 6, 'Guernsey', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:45', '2020-11-01 10:26:45'),
(35, 1, 'Micronesia', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:47', '2020-11-01 10:26:47'),
(36, 2, 'New Caledonia', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:48', '2020-11-01 10:26:48'),
(37, 6, 'Guadeloupe', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:49', '2020-11-01 10:26:49'),
(38, 4, 'Saint Helena', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:51', '2020-11-01 10:26:51'),
(39, 6, 'Mexico', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:53', '2020-11-01 10:26:53'),
(40, 2, 'Tonga', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:56', '2020-11-01 10:26:56'),
(41, 2, 'Yemen', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:57', '2020-11-01 10:26:57'),
(42, 5, 'Portugal', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:00', '2020-11-01 10:27:00'),
(43, 1, 'Italy', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:02', '2020-11-01 10:27:02'),
(44, 2, 'Iceland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:04', '2020-11-01 10:27:04'),
(45, 1, 'Montserrat', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:05', '2020-11-01 10:27:05'),
(46, 6, 'Cyprus', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:07', '2020-11-01 10:27:07'),
(47, 3, 'Moldova', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:11', '2020-11-01 10:27:11'),
(48, 4, 'Poland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:13', '2020-11-01 10:27:13'),
(49, 3, 'Germany', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:14', '2020-11-01 10:27:14'),
(50, 7, 'Libyan Arab Jamahiriya', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:20', '2020-11-01 10:27:20'),
(51, 4, 'Sao Tome and Principe', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:21', '2020-11-01 10:27:21'),
(52, 7, 'Heard Island and McDonald Islands', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:23', '2020-11-01 10:27:23'),
(53, 3, 'Gambia', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:25', '2020-11-01 10:27:25'),
(54, 6, 'Netherlands', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:26', '2020-11-01 10:27:26'),
(55, 4, 'Slovenia', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:27', '2020-11-01 10:27:27'),
(56, 3, 'Sudan', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:28', '2020-11-01 10:27:28'),
(57, 2, 'Iceland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:29', '2020-11-01 10:27:29'),
(58, 6, 'Grenada', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:31', '2020-11-01 10:27:31'),
(59, 2, 'Faroe Islands', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:33', '2020-11-01 10:27:33'),
(60, 4, 'Netherlands Antilles', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:34', '2020-11-01 10:27:34'),
(61, 7, 'South Africa', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:35', '2020-11-01 10:27:35'),
(62, 3, 'Monaco', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:37', '2020-11-01 10:27:37'),
(63, 3, 'Samoa', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:40', '2020-11-01 10:27:40'),
(64, 6, 'Switzerland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:41', '2020-11-01 10:27:41'),
(65, 5, 'Bermuda', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:43', '2020-11-01 10:27:43'),
(66, 1, 'Cote d\'Ivoire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:45', '2020-11-01 10:27:45'),
(67, 5, 'Belize', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:49', '2020-11-01 10:27:49'),
(68, 5, 'Paraguay', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:50', '2020-11-01 10:27:50'),
(69, 4, 'Ecuador', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:51', '2020-11-01 10:27:51'),
(70, 7, 'Marshall Islands', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:54', '2020-11-01 10:27:54'),
(71, 7, 'Brazil', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:55', '2020-11-01 10:27:55'),
(72, 7, 'Palau', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:56', '2020-11-01 10:27:56'),
(73, 6, 'Lithuania', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:00', '2020-11-01 10:28:00'),
(74, 4, 'Haiti', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:01', '2020-11-01 10:28:01'),
(75, 4, 'Grenada', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:03', '2020-11-01 10:28:03'),
(76, 2, 'Nepal', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:05', '2020-11-01 10:28:05'),
(77, 1, 'Russian Federation', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:06', '2020-11-01 10:28:06'),
(78, 5, 'Congo', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:08', '2020-11-01 10:28:08'),
(79, 4, 'French Polynesia', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:09', '2020-11-01 10:28:09'),
(80, 1, 'Guyana', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:12', '2020-11-01 10:28:12'),
(81, 5, 'Mauritania', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:15', '2020-11-01 10:28:15'),
(82, 5, 'Lithuania', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:16', '2020-11-01 10:28:16'),
(83, 3, 'Malawi', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:19', '2020-11-01 10:28:19'),
(84, 1, 'Niue', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:21', '2020-11-01 10:28:21'),
(85, 1, 'Japan', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:23', '2020-11-01 10:28:23'),
(86, 5, 'Belarus', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:24', '2020-11-01 10:28:24'),
(87, 5, 'Swaziland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:25', '2020-11-01 10:28:25'),
(88, 6, 'Falkland Islands (Malvinas)', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:28', '2020-11-01 10:28:28'),
(89, 3, 'Niue', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:29', '2020-11-01 10:28:29'),
(90, 5, 'Bulgaria', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:31', '2020-11-01 10:28:31'),
(91, 7, 'Azerbaijan', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:32', '2020-11-01 10:28:32'),
(92, 4, 'Korea', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:34', '2020-11-01 10:28:34'),
(93, 2, 'China', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:36', '2020-11-01 10:28:36'),
(94, 7, 'Cambodia', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:39', '2020-11-01 10:28:39'),
(95, 3, 'Romania', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:40', '2020-11-01 10:28:40'),
(96, 1, 'Spain', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:41', '2020-11-01 10:28:41'),
(97, 7, 'Eritrea', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:42', '2020-11-01 10:28:42'),
(98, 4, 'Libyan Arab Jamahiriya', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:45', '2020-11-01 10:28:45'),
(99, 5, 'Trinidad and Tobago', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:49', '2020-11-01 10:28:49'),
(100, 1, 'Andorra', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:50', '2020-11-01 10:28:50'),
(101, 2, 'Sierra Leone', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:51', '2020-11-01 10:28:51'),
(102, 4, 'Saint Vincent and the Grenadines', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:52', '2020-11-01 10:28:52'),
(103, 3, 'Lebanon', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:53', '2020-11-01 10:28:53'),
(104, 7, 'Iceland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:55', '2020-11-01 10:28:55'),
(105, 4, 'Djibouti', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:58', '2020-11-01 10:28:58'),
(106, 3, 'Switzerland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:00', '2020-11-01 10:29:00'),
(107, 4, 'Mauritania', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:02', '2020-11-01 10:29:02'),
(108, 1, 'Macao', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:06', '2020-11-01 10:29:06'),
(109, 6, 'Bhutan', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:08', '2020-11-01 10:29:08'),
(110, 3, 'United States Minor Outlying Islands', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:12', '2020-11-01 10:29:12'),
(111, 4, 'Albania', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:21', '2020-11-01 10:29:21'),
(112, 3, 'Bouvet Island (Bouvetoya)', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:24', '2020-11-01 10:29:24'),
(113, 5, 'South Georgia and the South Sandwich Islands', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:25', '2020-11-01 10:29:25'),
(114, 1, 'Russian Federation', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:26', '2020-11-01 10:29:26'),
(115, 4, 'Cocos (Keeling) Islands', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:28', '2020-11-01 10:29:28'),
(116, 2, 'Italy', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:29', '2020-11-01 10:29:29'),
(117, 3, 'Korea', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:31', '2020-11-01 10:29:31'),
(118, 6, 'Guinea-Bissau', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:33', '2020-11-01 10:29:33'),
(119, 3, 'Andorra', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:35', '2020-11-01 10:29:35'),
(120, 2, 'Bahrain', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:37', '2020-11-01 10:29:37'),
(121, 7, 'Iraq', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:40', '2020-11-01 10:29:40'),
(122, 6, 'China', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:41', '2020-11-01 10:29:41'),
(123, 3, 'Guinea', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:42', '2020-11-01 10:29:42'),
(124, 7, 'Israel', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:43', '2020-11-01 10:29:43'),
(125, 6, 'Cote d\'Ivoire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:44', '2020-11-01 10:29:44'),
(126, 2, 'San Marino', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:47', '2020-11-01 10:29:47'),
(127, 5, 'Haiti', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:48', '2020-11-01 10:29:48'),
(128, 4, 'Macao', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:49', '2020-11-01 10:29:49');

INSERT INTO `city` (`id`, `country_id`, `name`, `population`, `area`, `no_roads`, `no_trees`, `no_shops`, `no_schools`, `stamp_created`, `stamp_modified`) VALUES
(1, 2, 'TOKYO', 13929, 2194, NULL, NULL, NULL, 2671, '2020-11-01 10:24:25', '2020-11-01 10:24:25'),
(2, 2, 'KYOTO', 1475, 827, NULL, NULL, NULL, 1000, '2020-11-01 10:24:25', '2020-11-01 10:24:25'),
(3, 1, 'South Michaelbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:31', '2020-11-01 10:24:31'),
(5, 1, 'Jacksonhaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:34', '2020-11-01 10:24:34'),
(7, 4, 'North Justin', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:39', '2020-11-01 10:24:39'),
(8, 1, 'Butlertown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:41', '2020-11-01 10:24:41'),
(9, 5, 'Tammyside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:42', '2020-11-01 10:24:42'),
(10, 1, 'Morrisshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:48', '2020-11-01 10:24:48'),
(11, 4, 'Barnesville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:50', '2020-11-01 10:24:50'),
(12, 7, 'West Mary', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:51', '2020-11-01 10:24:51'),
(13, 6, 'Powelltown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:53', '2020-11-01 10:24:53'),
(14, 4, 'West Davidchester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:54', '2020-11-01 10:24:54'),
(15, 6, 'Johnstonville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:56', '2020-11-01 10:24:56'),
(16, 4, 'Taylorfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:24:58', '2020-11-01 10:24:58'),
(17, 6, 'Robertville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:25:00', '2020-11-01 10:25:00'),
(18, 6, 'Rachelburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:25:01', '2020-11-01 10:25:01'),
(19, 6, 'Clarkmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:25:04', '2020-11-01 10:25:04'),
(20, 4, 'Moralesport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:25:07', '2020-11-01 10:25:07'),
(24, 21, 'North Richardbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:22', '2020-11-01 10:26:22'),
(28, 22, 'Paigemouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:29', '2020-11-01 10:26:29'),
(31, 21, 'East Haroldmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:39', '2020-11-01 10:26:39'),
(33, 24, 'Port Phillipside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:41', '2020-11-01 10:26:41'),
(35, 19, 'East Steven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:44', '2020-11-01 10:26:44'),
(36, 27, 'Randallbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:46', '2020-11-01 10:26:46'),
(37, 30, 'North Karenstad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:50', '2020-11-01 10:26:50'),
(39, 31, 'Nancyberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:54', '2020-11-01 10:26:54'),
(40, 12, 'Brendaville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:55', '2020-11-01 10:26:55'),
(41, 30, 'North Christina', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:58', '2020-11-01 10:26:58'),
(42, 36, 'Kimberlystad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:26:59', '2020-11-01 10:26:59'),
(43, 19, 'Lake Erikafort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:01', '2020-11-01 10:27:01'),
(44, 39, 'Smithhaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:03', '2020-11-01 10:27:03'),
(45, 40, 'New Kathymouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:06', '2020-11-01 10:27:06'),
(46, 23, 'Stephenfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:08', '2020-11-01 10:27:08'),
(47, 24, 'Jillberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:09', '2020-11-01 10:27:09'),
(48, 43, 'South Sherristad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:10', '2020-11-01 10:27:10'),
(49, 41, 'Cynthiashire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:12', '2020-11-01 10:27:12'),
(50, 22, 'Scottfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:15', '2020-11-01 10:27:15'),
(51, 41, 'Reginamouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:16', '2020-11-01 10:27:16'),
(52, 11, 'Port Rodneyhaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:17', '2020-11-01 10:27:17'),
(53, 43, 'East Sandramouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:19', '2020-11-01 10:27:19'),
(54, 10, 'Port Baileybury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:22', '2020-11-01 10:27:22'),
(55, 17, 'Staceyton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:24', '2020-11-01 10:27:24'),
(56, 7, 'New Glenn', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:30', '2020-11-01 10:27:30'),
(57, 20, 'New Amy', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:32', '2020-11-01 10:27:32'),
(58, 27, 'Tracymouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:36', '2020-11-01 10:27:36'),
(59, 16, 'Brownshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:38', '2020-11-01 10:27:38'),
(60, 31, 'Friedmanville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:39', '2020-11-01 10:27:39'),
(61, 25, 'Catherinetown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:42', '2020-11-01 10:27:42'),
(62, 35, 'Lake Danielleland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:44', '2020-11-01 10:27:44'),
(63, 13, 'Mackfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:46', '2020-11-01 10:27:46'),
(64, 16, 'Davidside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:47', '2020-11-01 10:27:47'),
(65, 23, 'Jamesfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:48', '2020-11-01 10:27:48'),
(66, 13, 'Lake Jacob', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:53', '2020-11-01 10:27:53'),
(67, 27, 'New Andrewfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:57', '2020-11-01 10:27:57'),
(68, 21, 'North Paul', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:58', '2020-11-01 10:27:58'),
(69, 13, 'Port Donald', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:27:59', '2020-11-01 10:27:59'),
(70, 27, 'Lake Cindyhaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:02', '2020-11-01 10:28:02'),
(71, 49, 'Herreraton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:04', '2020-11-01 10:28:04'),
(72, 31, 'Port Justinchester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:07', '2020-11-01 10:28:07'),
(73, 27, 'Thomasmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:10', '2020-11-01 10:28:10'),
(74, 44, 'Port Johnnyview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:11', '2020-11-01 10:28:11'),
(75, 35, 'Amandaland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:13', '2020-11-01 10:28:13'),
(76, 17, 'South Donnaville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:14', '2020-11-01 10:28:14'),
(77, 19, 'Bryantborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:17', '2020-11-01 10:28:17'),
(78, 26, 'East Lorettashire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:18', '2020-11-01 10:28:18'),
(79, 48, 'North Donna', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:20', '2020-11-01 10:28:20'),
(80, 20, 'West Kimberlyview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:26', '2020-11-01 10:28:26'),
(81, 35, 'West Kaylaborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:27', '2020-11-01 10:28:27'),
(82, 43, 'Stephaniefurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:30', '2020-11-01 10:28:30'),
(83, 41, 'Thomasfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:33', '2020-11-01 10:28:33'),
(84, 11, 'Claytonbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:35', '2020-11-01 10:28:35'),
(85, 15, 'Reedport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:37', '2020-11-01 10:28:37'),
(86, 46, 'West Eric', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:38', '2020-11-01 10:28:38'),
(87, 9, 'Stefaniechester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:43', '2020-11-01 10:28:43'),
(88, 36, 'Lisaland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:44', '2020-11-01 10:28:44'),
(89, 44, 'Denisefort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:46', '2020-11-01 10:28:46'),
(90, 50, 'Port Lucas', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:47', '2020-11-01 10:28:47'),
(91, 17, 'South Danielton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:48', '2020-11-01 10:28:48'),
(92, 30, 'North Normanborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:54', '2020-11-01 10:28:54'),
(93, 48, 'Jefferyfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:56', '2020-11-01 10:28:56'),
(94, 12, 'New Jennifer', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:57', '2020-11-01 10:28:57'),
(95, 47, 'South Bethberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:28:59', '2020-11-01 10:28:59'),
(96, 39, 'Hebertberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:01', '2020-11-01 10:29:01'),
(97, 37, 'Nicholasland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:03', '2020-11-01 10:29:03'),
(98, 42, 'Aguilarbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:04', '2020-11-01 10:29:04'),
(99, 36, 'Ryanview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:05', '2020-11-01 10:29:05'),
(100, 10, 'Port Toddmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:07', '2020-11-01 10:29:07'),
(101, 10, 'North Christopherbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:09', '2020-11-01 10:29:09'),
(102, 28, 'North Kaitlynside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:10', '2020-11-01 10:29:10'),
(103, 38, 'West Bethmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:11', '2020-11-01 10:29:11'),
(104, 11, 'West Audrey', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:13', '2020-11-01 10:29:13'),
(105, 22, 'Lake Ryan', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:14', '2020-11-01 10:29:14'),
(106, 46, 'North Valerie', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:16', '2020-11-01 10:29:16'),
(107, 12, 'Tapialand', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:17', '2020-11-01 10:29:17'),
(108, 7, 'West William', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:18', '2020-11-01 10:29:18'),
(109, 45, 'Lake Nathanstad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:19', '2020-11-01 10:29:19'),
(110, 25, 'South Austin', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:20', '2020-11-01 10:29:20'),
(111, 14, 'Hicksburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:22', '2020-11-01 10:29:22'),
(112, 41, 'South Whitneybury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:23', '2020-11-01 10:29:23'),
(113, 17, 'South Marcside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:27', '2020-11-01 10:29:27'),
(114, 46, 'Shellyton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:30', '2020-11-01 10:29:30'),
(115, 23, 'Dianatown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:32', '2020-11-01 10:29:32'),
(116, 23, 'New Kimberly', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:34', '2020-11-01 10:29:34'),
(117, 48, 'Johnsonchester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:36', '2020-11-01 10:29:36'),
(118, 33, 'Sandovalview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:38', '2020-11-01 10:29:38'),
(119, 35, 'Harveyborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:39', '2020-11-01 10:29:39'),
(120, 49, 'Jameschester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:29:45', '2020-11-01 10:29:45'),
(121, 11, 'Reedchester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:22', '2020-11-01 10:30:22'),
(122, 37, 'New Jessica', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:23', '2020-11-01 10:30:23'),
(123, 46, 'South Kathy', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:24', '2020-11-01 10:30:24'),
(124, 30, 'Nancybury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:25', '2020-11-01 10:30:25'),
(125, 114, 'New Christopher', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:26', '2020-11-01 10:30:26'),
(126, 92, 'North Ryanland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:27', '2020-11-01 10:30:27'),
(127, 29, 'Lindseystad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:28', '2020-11-01 10:30:28'),
(128, 90, 'Port Erin', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:29', '2020-11-01 10:30:29'),
(129, 80, 'South Sarah', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:30', '2020-11-01 10:30:30'),
(130, 58, 'Garciaville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:31', '2020-11-01 10:30:31'),
(131, 13, 'North Mariastad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:32', '2020-11-01 10:30:32'),
(132, 74, 'South Anthony', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:33', '2020-11-01 10:30:33'),
(133, 40, 'Lake Autumntown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:34', '2020-11-01 10:30:34'),
(134, 53, 'Johnsonburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:35', '2020-11-01 10:30:35'),
(135, 27, 'Lake Steven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:36', '2020-11-01 10:30:36'),
(136, 73, 'Cookfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:37', '2020-11-01 10:30:37'),
(137, 95, 'Shawmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:38', '2020-11-01 10:30:38'),
(138, 58, 'Lake Derekchester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:39', '2020-11-01 10:30:39'),
(139, 90, 'Lake Kathrynstad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:40', '2020-11-01 10:30:40'),
(140, 3, 'Bentleyfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:41', '2020-11-01 10:30:41'),
(141, 85, 'Gouldburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:42', '2020-11-01 10:30:42'),
(142, 114, 'Christopherland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:43', '2020-11-01 10:30:43'),
(143, 29, 'Lynnshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:44', '2020-11-01 10:30:44'),
(144, 7, 'Port Shelbyport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:45', '2020-11-01 10:30:45'),
(145, 54, 'South Jesus', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:46', '2020-11-01 10:30:46'),
(146, 75, 'West Valerie', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:47', '2020-11-01 10:30:47'),
(147, 18, 'Whitneyville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:48', '2020-11-01 10:30:48'),
(148, 66, 'Jordanland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:49', '2020-11-01 10:30:49'),
(149, 120, 'Riveraport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:50', '2020-11-01 10:30:50'),
(150, 33, 'Montesfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:51', '2020-11-01 10:30:51'),
(151, 78, 'West Kristenview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:52', '2020-11-01 10:30:52'),
(152, 44, 'North Jessefurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:54', '2020-11-01 10:30:54'),
(153, 36, 'North Carolynberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:55', '2020-11-01 10:30:55'),
(154, 121, 'Kristenborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:56', '2020-11-01 10:30:56'),
(155, 119, 'Crossfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:57', '2020-11-01 10:30:57'),
(156, 13, 'Atkinsonhaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:58', '2020-11-01 10:30:58'),
(157, 110, 'Jodiside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:30:59', '2020-11-01 10:30:59'),
(158, 45, 'Williamsshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:00', '2020-11-01 10:31:00'),
(159, 79, 'Martinezfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:01', '2020-11-01 10:31:01'),
(160, 29, 'Adamsshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:02', '2020-11-01 10:31:02'),
(161, 50, 'West Kristabury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:03', '2020-11-01 10:31:03'),
(162, 10, 'Sharpburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:04', '2020-11-01 10:31:04'),
(163, 46, 'Powersport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:05', '2020-11-01 10:31:05'),
(164, 10, 'South Brandonville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:06', '2020-11-01 10:31:06'),
(165, 87, 'Williamsport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:07', '2020-11-01 10:31:07'),
(166, 102, 'Alvinshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:08', '2020-11-01 10:31:08'),
(167, 108, 'South Bethville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:09', '2020-11-01 10:31:09'),
(168, 98, 'Lake Tammybury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:10', '2020-11-01 10:31:10'),
(169, 24, 'Lake Erinberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:11', '2020-11-01 10:31:11'),
(170, 114, 'West Luis', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:12', '2020-11-01 10:31:12'),
(171, 90, 'West Joan', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:13', '2020-11-01 10:31:13'),
(172, 114, 'Howardbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:14', '2020-11-01 10:31:14'),
(173, 107, 'Port Stacy', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:15', '2020-11-01 10:31:15'),
(174, 41, 'Sarahbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:16', '2020-11-01 10:31:16'),
(175, 119, 'Spencerton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:17', '2020-11-01 10:31:17'),
(176, 24, 'West Shannon', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:18', '2020-11-01 10:31:18'),
(177, 102, 'West Rose', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:19', '2020-11-01 10:31:19'),
(178, 79, 'South Nicolebury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:20', '2020-11-01 10:31:20'),
(179, 21, 'East Jessica', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:21', '2020-11-01 10:31:21'),
(180, 29, 'South Mary', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:22', '2020-11-01 10:31:22'),
(181, 60, 'Rodriguezshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:23', '2020-11-01 10:31:23'),
(182, 25, 'Melissamouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:24', '2020-11-01 10:31:24'),
(183, 82, 'Rebeccaberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:25', '2020-11-01 10:31:25'),
(184, 97, 'West John', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:26', '2020-11-01 10:31:26'),
(185, 62, 'Banksstad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:27', '2020-11-01 10:31:27'),
(186, 10, 'Smithtown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:28', '2020-11-01 10:31:28'),
(187, 116, 'North Michelleside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:30', '2020-11-01 10:31:30'),
(188, 43, 'Cookmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:31', '2020-11-01 10:31:31'),
(189, 60, 'Duarteburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:32', '2020-11-01 10:31:32'),
(190, 95, 'Morrisonport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:33', '2020-11-01 10:31:33'),
(191, 32, 'West John', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:34', '2020-11-01 10:31:34'),
(192, 120, 'Greenefurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:35', '2020-11-01 10:31:35'),
(193, 8, 'Cassandraside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:36', '2020-11-01 10:31:36'),
(194, 26, 'North Karentown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:37', '2020-11-01 10:31:37'),
(195, 27, 'South Kerri', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:38', '2020-11-01 10:31:38'),
(196, 63, 'Port Kimview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:39', '2020-11-01 10:31:39'),
(197, 110, 'South Francesshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:40', '2020-11-01 10:31:40'),
(198, 52, 'New Warrenmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:41', '2020-11-01 10:31:41'),
(199, 124, 'North Debbiestad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:42', '2020-11-01 10:31:42'),
(200, 41, 'Antoniomouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:43', '2020-11-01 10:31:43'),
(201, 36, 'Port Angelafurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:44', '2020-11-01 10:31:44'),
(202, 39, 'Butlerville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:45', '2020-11-01 10:31:45'),
(203, 46, 'South Toniport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:46', '2020-11-01 10:31:46'),
(204, 8, 'Fullertown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:47', '2020-11-01 10:31:47'),
(205, 15, 'Amandaside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:48', '2020-11-01 10:31:48'),
(206, 83, 'East Dianetown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:49', '2020-11-01 10:31:49'),
(207, 47, 'New Angelabury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:50', '2020-11-01 10:31:50'),
(208, 14, 'New Katherinebury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:51', '2020-11-01 10:31:51'),
(209, 25, 'Tinamouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:52', '2020-11-01 10:31:52'),
(210, 14, 'Thomasshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:53', '2020-11-01 10:31:53'),
(211, 19, 'East Amandaside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:54', '2020-11-01 10:31:54'),
(212, 110, 'Lake Eric', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:55', '2020-11-01 10:31:55'),
(213, 37, 'Port Erikafurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:56', '2020-11-01 10:31:56'),
(214, 51, 'Bakerport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:57', '2020-11-01 10:31:57'),
(215, 9, 'East Mariabury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:58', '2020-11-01 10:31:58'),
(216, 119, 'Davidborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:31:59', '2020-11-01 10:31:59'),
(217, 24, 'Port Hannah', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:00', '2020-11-01 10:32:00'),
(218, 86, 'Douglasmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:01', '2020-11-01 10:32:01'),
(219, 96, 'East William', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:02', '2020-11-01 10:32:02'),
(220, 50, 'South Amanda', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:03', '2020-11-01 10:32:03'),
(221, 109, 'Lake Greg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:04', '2020-11-01 10:32:04'),
(222, 109, 'South Courtneyburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:05', '2020-11-01 10:32:05'),
(223, 26, 'Amberport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:06', '2020-11-01 10:32:06'),
(224, 36, 'Rayberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:07', '2020-11-01 10:32:07'),
(225, 121, 'North Brenda', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:08', '2020-11-01 10:32:08'),
(226, 97, 'South Michelle', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:09', '2020-11-01 10:32:09'),
(227, 107, 'Carolynmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:10', '2020-11-01 10:32:10'),
(228, 51, 'Soniafurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:11', '2020-11-01 10:32:11'),
(229, 46, 'Hintonview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:12', '2020-11-01 10:32:12'),
(230, 53, 'Lake Dennisland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:13', '2020-11-01 10:32:13'),
(231, 27, 'West Gwendolynfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:14', '2020-11-01 10:32:14'),
(232, 30, 'Elizabethside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:15', '2020-11-01 10:32:15'),
(233, 92, 'East Joshuaville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:16', '2020-11-01 10:32:16'),
(234, 14, 'Kylestad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:17', '2020-11-01 10:32:17'),
(235, 75, 'Bryanborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:18', '2020-11-01 10:32:18'),
(236, 100, 'East Thomasville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:20', '2020-11-01 10:32:20'),
(237, 76, 'Perezfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:21', '2020-11-01 10:32:21'),
(238, 10, 'East Anneland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:22', '2020-11-01 10:32:22'),
(239, 106, 'New Georgeborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:23', '2020-11-01 10:32:23'),
(240, 68, 'West Mary', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:24', '2020-11-01 10:32:24'),
(241, 52, 'North Seanburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:25', '2020-11-01 10:32:25'),
(242, 62, 'New Christopher', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:26', '2020-11-01 10:32:26'),
(243, 16, 'Angelaville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:27', '2020-11-01 10:32:27'),
(244, 118, 'Clayside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:28', '2020-11-01 10:32:28'),
(245, 95, 'Cookland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:29', '2020-11-01 10:32:29'),
(246, 114, 'New Stephanie', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:30', '2020-11-01 10:32:30'),
(247, 35, 'West Kellystad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:31', '2020-11-01 10:32:31'),
(248, 20, 'Lake Megan', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:32', '2020-11-01 10:32:32'),
(249, 82, 'Andrewsview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:33', '2020-11-01 10:32:33'),
(250, 23, 'South Robinborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:34', '2020-11-01 10:32:34'),
(251, 123, 'West Brett', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:35', '2020-11-01 10:32:35'),
(252, 16, 'New Sabrinaville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:36', '2020-11-01 10:32:36'),
(253, 66, 'Turnerberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:37', '2020-11-01 10:32:37'),
(254, 66, 'Harrisontown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:38', '2020-11-01 10:32:38'),
(255, 124, 'Markton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:39', '2020-11-01 10:32:39'),
(256, 9, 'New Travis', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:40', '2020-11-01 10:32:40'),
(257, 69, 'South John', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:41', '2020-11-01 10:32:41'),
(258, 97, 'Valdezbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:42', '2020-11-01 10:32:42'),
(259, 20, 'Robinshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:43', '2020-11-01 10:32:43'),
(260, 41, 'Teresaside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:44', '2020-11-01 10:32:44'),
(261, 75, 'Angelaborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:45', '2020-11-01 10:32:45'),
(262, 96, 'Stephenbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:46', '2020-11-01 10:32:46'),
(263, 17, 'South Troyborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:47', '2020-11-01 10:32:47'),
(264, 112, 'East Chelsea', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:48', '2020-11-01 10:32:48'),
(265, 105, 'Ramosberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:49', '2020-11-01 10:32:49'),
(266, 31, 'Boydbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:50', '2020-11-01 10:32:50'),
(267, 56, 'Lake Kaylastad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:51', '2020-11-01 10:32:51'),
(268, 37, 'Lake Jacobview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:52', '2020-11-01 10:32:52'),
(269, 1, 'Carrport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:53', '2020-11-01 10:32:53'),
(270, 64, 'Michaelside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:54', '2020-11-01 10:32:54'),
(271, 42, 'Coxbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:55', '2020-11-01 10:32:55'),
(272, 56, 'Averystad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:56', '2020-11-01 10:32:56'),
(273, 88, 'South Jamesburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:57', '2020-11-01 10:32:57'),
(274, 17, 'East Christina', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:58', '2020-11-01 10:32:58'),
(275, 95, 'Gonzalesmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:32:59', '2020-11-01 10:32:59'),
(276, 12, 'West Denise', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:00', '2020-11-01 10:33:00'),
(277, 120, 'South Erica', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:01', '2020-11-01 10:33:01'),
(278, 116, 'Lake Dylantown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:02', '2020-11-01 10:33:02'),
(279, 77, 'North John', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:03', '2020-11-01 10:33:03'),
(280, 6, 'Christopherstad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:04', '2020-11-01 10:33:04'),
(281, 23, 'Warestad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:05', '2020-11-01 10:33:05'),
(282, 122, 'Kendrafurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:06', '2020-11-01 10:33:06'),
(283, 96, 'Galvanton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:07', '2020-11-01 10:33:07'),
(284, 93, 'Johnsonstad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:08', '2020-11-01 10:33:08'),
(285, 46, 'South Lori', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:09', '2020-11-01 10:33:09'),
(286, 32, 'North Nicole', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:10', '2020-11-01 10:33:10'),
(287, 93, 'Lake Martinbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:11', '2020-11-01 10:33:11'),
(288, 6, 'South Autumnmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:12', '2020-11-01 10:33:12'),
(289, 7, 'Port Tammyport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:13', '2020-11-01 10:33:13'),
(290, 37, 'Austinchester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:14', '2020-11-01 10:33:14'),
(291, 33, 'Mayhaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:15', '2020-11-01 10:33:15'),
(292, 70, 'Timothyfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:16', '2020-11-01 10:33:16'),
(293, 30, 'Annamouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:17', '2020-11-01 10:33:17'),
(294, 25, 'New Christineberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:18', '2020-11-01 10:33:18'),
(295, 92, 'North Carrie', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:20', '2020-11-01 10:33:20'),
(296, 110, 'Rhondaberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:21', '2020-11-01 10:33:21'),
(297, 42, 'New Maria', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:22', '2020-11-01 10:33:22'),
(298, 69, 'Port Jackieville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:23', '2020-11-01 10:33:23'),
(299, 38, 'Grantfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:24', '2020-11-01 10:33:24'),
(300, 32, 'West Kelseyfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:25', '2020-11-01 10:33:25'),
(301, 32, 'South David', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:26', '2020-11-01 10:33:26'),
(302, 1, 'Austinton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:27', '2020-11-01 10:33:27'),
(303, 98, 'Lake Maria', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:28', '2020-11-01 10:33:28'),
(304, 5, 'North Randy', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:29', '2020-11-01 10:33:29'),
(305, 117, 'West Brenda', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:30', '2020-11-01 10:33:30'),
(306, 7, 'Jasontown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:31', '2020-11-01 10:33:31'),
(307, 111, 'Bradyside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:32', '2020-11-01 10:33:32'),
(308, 43, 'Villarrealchester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:33', '2020-11-01 10:33:33'),
(309, 102, 'Lauraport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:34', '2020-11-01 10:33:34'),
(310, 12, 'Matthewburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:35', '2020-11-01 10:33:35'),
(311, 7, 'East Ethan', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:36', '2020-11-01 10:33:36'),
(312, 51, 'Williamton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:37', '2020-11-01 10:33:37'),
(313, 34, 'Johnsonfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:38', '2020-11-01 10:33:38'),
(314, 109, 'New Arthurshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:39', '2020-11-01 10:33:39'),
(315, 112, 'Beckland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:40', '2020-11-01 10:33:40'),
(316, 123, 'West Ashley', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:41', '2020-11-01 10:33:41'),
(317, 102, 'South Chelsea', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:42', '2020-11-01 10:33:42'),
(318, 120, 'New Susanstad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:43', '2020-11-01 10:33:43'),
(319, 54, 'Port Michaelport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:44', '2020-11-01 10:33:44'),
(320, 111, 'Port Larrytown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:45', '2020-11-01 10:33:45'),
(321, 115, 'Stephensville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:46', '2020-11-01 10:33:46'),
(322, 27, 'Debraport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:47', '2020-11-01 10:33:47'),
(323, 93, 'South Diane', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:48', '2020-11-01 10:33:48'),
(324, 116, 'Smithtown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:49', '2020-11-01 10:33:49'),
(325, 3, 'Lindaland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:50', '2020-11-01 10:33:50'),
(326, 98, 'North Sarah', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:51', '2020-11-01 10:33:51'),
(327, 109, 'Lake Gabrielmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:52', '2020-11-01 10:33:52'),
(328, 105, 'West Kellyside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:53', '2020-11-01 10:33:53'),
(329, 33, 'Coxfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:54', '2020-11-01 10:33:54'),
(330, 53, 'East Andrewshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:55', '2020-11-01 10:33:55'),
(331, 98, 'West Aaron', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:56', '2020-11-01 10:33:56'),
(332, 60, 'Deanfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:57', '2020-11-01 10:33:57'),
(333, 121, 'Tonitown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:58', '2020-11-01 10:33:58'),
(334, 105, 'New Jessicaborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:33:59', '2020-11-01 10:33:59'),
(335, 81, 'Padillabury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:00', '2020-11-01 10:34:00'),
(336, 114, 'South Bethany', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:01', '2020-11-01 10:34:01'),
(337, 15, 'Vickieville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:02', '2020-11-01 10:34:02'),
(338, 46, 'Wendyton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:03', '2020-11-01 10:34:03'),
(339, 28, 'Paulport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:04', '2020-11-01 10:34:04'),
(340, 46, 'Brockhaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:05', '2020-11-01 10:34:05'),
(341, 116, 'Greeneport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:06', '2020-11-01 10:34:06'),
(342, 125, 'Lake Sara', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:07', '2020-11-01 10:34:07'),
(343, 8, 'North Dawnberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:08', '2020-11-01 10:34:08'),
(344, 100, 'South Stephen', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:09', '2020-11-01 10:34:09'),
(345, 118, 'Port Toddview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:10', '2020-11-01 10:34:10'),
(346, 14, 'Amandashire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:11', '2020-11-01 10:34:11'),
(347, 30, 'East Matthew', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:12', '2020-11-01 10:34:12'),
(348, 84, 'Port Michael', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:13', '2020-11-01 10:34:13'),
(349, 99, 'Bensonmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:14', '2020-11-01 10:34:14'),
(350, 9, 'North Jacqueline', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:15', '2020-11-01 10:34:15'),
(351, 96, 'South Elizabeth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:17', '2020-11-01 10:34:17'),
(352, 29, 'East Dawnberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:18', '2020-11-01 10:34:18'),
(353, 91, 'West Anna', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:19', '2020-11-01 10:34:19'),
(354, 5, 'Joshuatown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:20', '2020-11-01 10:34:20'),
(355, 74, 'West Christianborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:21', '2020-11-01 10:34:21'),
(356, 67, 'Adamsfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:22', '2020-11-01 10:34:22'),
(357, 106, 'Deckerburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:23', '2020-11-01 10:34:23'),
(358, 13, 'Port David', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:24', '2020-11-01 10:34:24'),
(359, 116, 'Markstad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:25', '2020-11-01 10:34:25'),
(360, 13, 'Wilsonchester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:26', '2020-11-01 10:34:26'),
(361, 13, 'Lake Luis', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:27', '2020-11-01 10:34:27'),
(362, 29, 'Leechester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:28', '2020-11-01 10:34:28'),
(363, 23, 'North Jennyberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:29', '2020-11-01 10:34:29'),
(364, 121, 'New Bridget', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:30', '2020-11-01 10:34:30'),
(365, 56, 'Smithton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:31', '2020-11-01 10:34:31'),
(366, 78, 'Port Aliciafort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:32', '2020-11-01 10:34:32'),
(367, 4, 'North Nicholas', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:33', '2020-11-01 10:34:33'),
(368, 122, 'South Brettfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:34', '2020-11-01 10:34:34'),
(369, 18, 'Carsonstad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:35', '2020-11-01 10:34:35'),
(370, 48, 'Gregorybury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:36', '2020-11-01 10:34:36'),
(371, 52, 'West Haroldberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:37', '2020-11-01 10:34:37'),
(372, 23, 'West Brandi', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:38', '2020-11-01 10:34:38'),
(373, 29, 'South Michaelburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:39', '2020-11-01 10:34:39'),
(374, 86, 'Smithmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:40', '2020-11-01 10:34:40'),
(375, 76, 'Michealside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:41', '2020-11-01 10:34:41'),
(376, 101, 'Sarahton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:42', '2020-11-01 10:34:42'),
(377, 94, 'Port Mandy', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:43', '2020-11-01 10:34:43'),
(378, 72, 'Lake Dustin', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:44', '2020-11-01 10:34:44'),
(379, 36, 'Gilmoreborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:45', '2020-11-01 10:34:45'),
(380, 121, 'Lake Connie', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:46', '2020-11-01 10:34:46'),
(381, 103, 'South Rebeccaborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:47', '2020-11-01 10:34:47'),
(382, 108, 'New Margaretland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:48', '2020-11-01 10:34:48'),
(383, 96, 'North Christytown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:49', '2020-11-01 10:34:49'),
(384, 65, 'Elizabethborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:50', '2020-11-01 10:34:50'),
(385, 42, 'Johnsberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:51', '2020-11-01 10:34:51'),
(386, 104, 'North Danielle', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:52', '2020-11-01 10:34:52'),
(387, 77, 'Charlesberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:53', '2020-11-01 10:34:53'),
(388, 35, 'East Kaylaview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:54', '2020-11-01 10:34:54'),
(389, 72, 'Port Cassandra', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:55', '2020-11-01 10:34:55'),
(390, 91, 'West Kyle', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:56', '2020-11-01 10:34:56'),
(391, 3, 'South Patrickville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:57', '2020-11-01 10:34:57'),
(392, 121, 'East Patriciamouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:58', '2020-11-01 10:34:58'),
(393, 54, 'East Margaretbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:34:59', '2020-11-01 10:34:59'),
(394, 50, 'Lauramouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:00', '2020-11-01 10:35:00'),
(395, 85, 'West Christine', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:01', '2020-11-01 10:35:01'),
(396, 68, 'Justinfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:02', '2020-11-01 10:35:02'),
(397, 84, 'Kevinton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:03', '2020-11-01 10:35:03'),
(398, 96, 'West Rodney', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:04', '2020-11-01 10:35:04'),
(399, 103, 'South Debrashire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:05', '2020-11-01 10:35:05'),
(400, 12, 'Salasmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:06', '2020-11-01 10:35:06'),
(401, 77, 'West Trevor', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:07', '2020-11-01 10:35:07'),
(402, 68, 'Johnport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:08', '2020-11-01 10:35:08'),
(403, 73, 'Ginaville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:09', '2020-11-01 10:35:09'),
(404, 68, 'South Angelamouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:11', '2020-11-01 10:35:11'),
(405, 83, 'Snowtown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:12', '2020-11-01 10:35:12'),
(406, 112, 'Smithmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:13', '2020-11-01 10:35:13'),
(407, 14, 'Lake Colleenbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:14', '2020-11-01 10:35:14'),
(408, 46, 'Saunderston', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:15', '2020-11-01 10:35:15'),
(409, 69, 'Andrewchester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:16', '2020-11-01 10:35:16'),
(410, 14, 'Jacobhaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:17', '2020-11-01 10:35:17'),
(411, 69, 'Port Danielleland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:18', '2020-11-01 10:35:18'),
(412, 80, 'South Sharonfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:19', '2020-11-01 10:35:19'),
(413, 69, 'Tuckerstad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:20', '2020-11-01 10:35:20'),
(414, 115, 'Christensenton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:21', '2020-11-01 10:35:21'),
(415, 60, 'South Daniel', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:22', '2020-11-01 10:35:22'),
(416, 26, 'Jenniferbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:23', '2020-11-01 10:35:23'),
(417, 80, 'Drakehaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:24', '2020-11-01 10:35:24'),
(418, 72, 'Brianstad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:25', '2020-11-01 10:35:25'),
(419, 105, 'East Johnfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:26', '2020-11-01 10:35:26'),
(420, 21, 'New Williamfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:27', '2020-11-01 10:35:27'),
(421, 19, 'Lake Kevin', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:28', '2020-11-01 10:35:28'),
(422, 122, 'Lake Jadestad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:29', '2020-11-01 10:35:29'),
(423, 103, 'North Richard', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:30', '2020-11-01 10:35:30'),
(424, 14, 'Joneston', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:31', '2020-11-01 10:35:31'),
(425, 39, 'Jamesburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:32', '2020-11-01 10:35:32'),
(426, 119, 'North Emilyshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:33', '2020-11-01 10:35:33'),
(427, 124, 'Rogerston', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:34', '2020-11-01 10:35:34'),
(428, 49, 'Bauertown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:35', '2020-11-01 10:35:35'),
(429, 88, 'Port Emilytown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:36', '2020-11-01 10:35:36'),
(430, 100, 'South Tina', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:37', '2020-11-01 10:35:37'),
(431, 82, 'East Sarah', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:38', '2020-11-01 10:35:38'),
(432, 97, 'Port Daniel', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:39', '2020-11-01 10:35:39'),
(433, 89, 'Hawkinsmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:40', '2020-11-01 10:35:40'),
(434, 10, 'New Harold', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:41', '2020-11-01 10:35:41'),
(435, 102, 'Jameschester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:42', '2020-11-01 10:35:42'),
(436, 73, 'Port Deborahland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:43', '2020-11-01 10:35:43'),
(437, 72, 'Jermainemouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:44', '2020-11-01 10:35:44'),
(438, 125, 'South Cassieview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:45', '2020-11-01 10:35:45'),
(439, 109, 'Perezhaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:46', '2020-11-01 10:35:46'),
(440, 32, 'Port Kathleenmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:47', '2020-11-01 10:35:47'),
(441, 75, 'Douglasfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:48', '2020-11-01 10:35:48'),
(442, 115, 'New Darren', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:49', '2020-11-01 10:35:49'),
(443, 63, 'Lake Robertfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:50', '2020-11-01 10:35:50'),
(444, 61, 'New Ashleymouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:51', '2020-11-01 10:35:51'),
(445, 49, 'Christianmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:52', '2020-11-01 10:35:52'),
(446, 57, 'Shaneview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:53', '2020-11-01 10:35:53'),
(447, 55, 'South Daniellemouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:54', '2020-11-01 10:35:54'),
(448, 64, 'West Samanthaberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:55', '2020-11-01 10:35:55'),
(449, 52, 'New Paul', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:56', '2020-11-01 10:35:56'),
(450, 114, 'East Davidmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:57', '2020-11-01 10:35:57'),
(451, 50, 'Mariaville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:58', '2020-11-01 10:35:58'),
(452, 81, 'North Rachelton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:35:59', '2020-11-01 10:35:59'),
(453, 122, 'Clarkberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:00', '2020-11-01 10:36:00'),
(454, 12, 'East Jason', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:01', '2020-11-01 10:36:01'),
(455, 31, 'Jacksonfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:02', '2020-11-01 10:36:02'),
(456, 76, 'Benjaminstad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:03', '2020-11-01 10:36:03'),
(457, 66, 'Gregoryside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:04', '2020-11-01 10:36:04'),
(458, 57, 'Port Jessica', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:05', '2020-11-01 10:36:05'),
(459, 69, 'Thompsontown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:06', '2020-11-01 10:36:06'),
(460, 27, 'Laurenport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:07', '2020-11-01 10:36:07'),
(461, 85, 'Hartmanhaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:08', '2020-11-01 10:36:08'),
(462, 92, 'East Chelseaborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:10', '2020-11-01 10:36:10'),
(463, 36, 'Teresabury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:11', '2020-11-01 10:36:11'),
(464, 61, 'West Ashley', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:12', '2020-11-01 10:36:12'),
(465, 28, 'Kathrynbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:13', '2020-11-01 10:36:13'),
(466, 29, 'Heatherland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:14', '2020-11-01 10:36:14'),
(467, 16, 'South Elizabethbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:15', '2020-11-01 10:36:15'),
(468, 43, 'Ronaldview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:16', '2020-11-01 10:36:16'),
(469, 19, 'South Bryce', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:17', '2020-11-01 10:36:17'),
(470, 82, 'Murphybury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:18', '2020-11-01 10:36:18'),
(471, 76, 'Jonathanmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:19', '2020-11-01 10:36:19'),
(472, 26, 'New Jeffery', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:20', '2020-11-01 10:36:20'),
(473, 75, 'Myersfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:21', '2020-11-01 10:36:21'),
(474, 51, 'Port Robert', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:22', '2020-11-01 10:36:22'),
(475, 31, 'Thomasmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:23', '2020-11-01 10:36:23'),
(476, 27, 'Lake Hunterview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:24', '2020-11-01 10:36:24'),
(477, 68, 'Nunezshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:25', '2020-11-01 10:36:25'),
(478, 72, 'West Danielchester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:26', '2020-11-01 10:36:26'),
(479, 21, 'New Keith', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:27', '2020-11-01 10:36:27');
INSERT INTO `city` (`id`, `country_id`, `name`, `population`, `area`, `no_roads`, `no_trees`, `no_shops`, `no_schools`, `stamp_created`, `stamp_modified`) VALUES
(480, 59, 'Morganbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:28', '2020-11-01 10:36:28'),
(481, 76, 'Lake Robertstad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:29', '2020-11-01 10:36:29'),
(482, 90, 'North Stephanie', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:30', '2020-11-01 10:36:30'),
(483, 29, 'Tracyport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:31', '2020-11-01 10:36:31'),
(484, 124, 'New Angelafurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:32', '2020-11-01 10:36:32'),
(485, 88, 'Melissamouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:33', '2020-11-01 10:36:33'),
(486, 65, 'Lake Rodneyberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:34', '2020-11-01 10:36:34'),
(487, 46, 'Nealburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:35', '2020-11-01 10:36:35'),
(488, 57, 'Port Charles', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:36', '2020-11-01 10:36:36'),
(489, 34, 'Taylorbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:37', '2020-11-01 10:36:37'),
(490, 93, 'Clarkfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:38', '2020-11-01 10:36:38'),
(491, 118, 'Crystalland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:39', '2020-11-01 10:36:39'),
(492, 65, 'Spencerport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:40', '2020-11-01 10:36:40'),
(493, 43, 'Port Jeffrey', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:41', '2020-11-01 10:36:41'),
(494, 64, 'Johnstad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:42', '2020-11-01 10:36:42'),
(495, 70, 'Lake Frank', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:43', '2020-11-01 10:36:43'),
(496, 82, 'Lake Ebonyhaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:44', '2020-11-01 10:36:44'),
(497, 40, 'Courtneymouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:45', '2020-11-01 10:36:45'),
(498, 64, 'Evansmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:46', '2020-11-01 10:36:46'),
(499, 31, 'North Bianca', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:47', '2020-11-01 10:36:47'),
(500, 4, 'Lawrenceside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:48', '2020-11-01 10:36:48'),
(501, 111, 'Scotthaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:49', '2020-11-01 10:36:49'),
(502, 61, 'Port Andrehaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:50', '2020-11-01 10:36:50'),
(503, 70, 'Sallymouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:51', '2020-11-01 10:36:51'),
(504, 41, 'East Jodiborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:52', '2020-11-01 10:36:52'),
(505, 70, 'Davidberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:53', '2020-11-01 10:36:53'),
(506, 36, 'Butlerhaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:54', '2020-11-01 10:36:54'),
(507, 26, 'Rebeccaland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:55', '2020-11-01 10:36:55'),
(508, 59, 'South Tracey', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:56', '2020-11-01 10:36:56'),
(509, 7, 'West Beverly', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:57', '2020-11-01 10:36:57'),
(510, 51, 'South Marthabury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:58', '2020-11-01 10:36:58'),
(511, 3, 'South Lisa', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:36:59', '2020-11-01 10:36:59'),
(512, 112, 'New Charles', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:00', '2020-11-01 10:37:00'),
(513, 42, 'Port Charlotte', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:01', '2020-11-01 10:37:01'),
(514, 50, 'Port Amberside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:02', '2020-11-01 10:37:02'),
(515, 92, 'Clarkmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:03', '2020-11-01 10:37:03'),
(516, 22, 'East Mistyport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:04', '2020-11-01 10:37:04'),
(517, 77, 'New Lynnton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:05', '2020-11-01 10:37:05'),
(518, 52, 'Hollandview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:06', '2020-11-01 10:37:06'),
(519, 85, 'Joneshaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:08', '2020-11-01 10:37:08'),
(520, 46, 'Lake Daisychester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:09', '2020-11-01 10:37:09'),
(521, 60, 'Port Robertview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:10', '2020-11-01 10:37:10'),
(522, 94, 'Codyport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:11', '2020-11-01 10:37:11'),
(523, 122, 'North Andrewside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:12', '2020-11-01 10:37:12'),
(524, 55, 'Sherriberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:13', '2020-11-01 10:37:13'),
(525, 30, 'East Susanbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:14', '2020-11-01 10:37:14'),
(526, 122, 'West Joshua', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:15', '2020-11-01 10:37:15'),
(527, 103, 'Murphyborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:16', '2020-11-01 10:37:16'),
(528, 49, 'New Loristad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:17', '2020-11-01 10:37:17'),
(529, 41, 'Lake Danielside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:18', '2020-11-01 10:37:18'),
(530, 1, 'Stephaniehaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:19', '2020-11-01 10:37:19'),
(531, 88, 'Benjaminfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:20', '2020-11-01 10:37:20'),
(532, 13, 'Grayburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:21', '2020-11-01 10:37:21'),
(533, 31, 'Port Shari', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:22', '2020-11-01 10:37:22'),
(534, 92, 'East Thomasburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:23', '2020-11-01 10:37:23'),
(535, 80, 'East Michael', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:24', '2020-11-01 10:37:24'),
(536, 62, 'Samanthaport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:25', '2020-11-01 10:37:25'),
(537, 65, 'Port Nathanbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:26', '2020-11-01 10:37:26'),
(538, 70, 'South Gina', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:27', '2020-11-01 10:37:27'),
(539, 29, 'Christinaberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:28', '2020-11-01 10:37:28'),
(540, 104, 'Port Teresaport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:29', '2020-11-01 10:37:29'),
(541, 95, 'Rogerhaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:30', '2020-11-01 10:37:30'),
(542, 65, 'Port Patrickhaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:31', '2020-11-01 10:37:31'),
(543, 91, 'Amandatown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:32', '2020-11-01 10:37:32'),
(544, 80, 'New Nancy', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:33', '2020-11-01 10:37:33'),
(545, 78, 'North Tylerchester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:34', '2020-11-01 10:37:34'),
(546, 65, 'South Jackie', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:35', '2020-11-01 10:37:35'),
(547, 106, 'East Angela', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:36', '2020-11-01 10:37:36'),
(548, 65, 'Lisaborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:37', '2020-11-01 10:37:37'),
(549, 15, 'Davidland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:38', '2020-11-01 10:37:38'),
(550, 33, 'New Courtneyton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:39', '2020-11-01 10:37:39'),
(551, 91, 'Aprilmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:40', '2020-11-01 10:37:40'),
(552, 13, 'Sanchezburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:41', '2020-11-01 10:37:41'),
(553, 46, 'East Virginia', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:42', '2020-11-01 10:37:42'),
(554, 47, 'South Ericborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:43', '2020-11-01 10:37:43'),
(555, 90, 'West Ryan', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:44', '2020-11-01 10:37:44'),
(556, 45, 'Staceyfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:45', '2020-11-01 10:37:45'),
(557, 3, 'Jasonhaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:46', '2020-11-01 10:37:46'),
(558, 64, 'New Justinberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:47', '2020-11-01 10:37:47'),
(559, 8, 'Joshuatown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:48', '2020-11-01 10:37:48'),
(560, 106, 'Brooksstad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:49', '2020-11-01 10:37:49'),
(561, 40, 'Webbshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:50', '2020-11-01 10:37:50'),
(562, 39, 'Paulhaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:51', '2020-11-01 10:37:51'),
(563, 121, 'South Brianstad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:52', '2020-11-01 10:37:52'),
(564, 111, 'East Jasonberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:53', '2020-11-01 10:37:53'),
(565, 76, 'West Nancy', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:54', '2020-11-01 10:37:54'),
(566, 69, 'Lutzberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:55', '2020-11-01 10:37:55'),
(567, 64, 'Vazquezland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:56', '2020-11-01 10:37:56'),
(568, 14, 'South Dana', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:57', '2020-11-01 10:37:57'),
(569, 45, 'Rosechester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:58', '2020-11-01 10:37:58'),
(570, 122, 'Erinborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:37:59', '2020-11-01 10:37:59'),
(571, 93, 'Navarroshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:00', '2020-11-01 10:38:00'),
(572, 73, 'West Tammy', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:01', '2020-11-01 10:38:01'),
(573, 57, 'Michaelhaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:02', '2020-11-01 10:38:02'),
(574, 41, 'Gregburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:03', '2020-11-01 10:38:03'),
(575, 49, 'Mistytown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:04', '2020-11-01 10:38:04'),
(576, 118, 'Thomasmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:05', '2020-11-01 10:38:05'),
(577, 22, 'New Kylebury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:07', '2020-11-01 10:38:07'),
(578, 66, 'West Michelleland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:08', '2020-11-01 10:38:08'),
(579, 31, 'East Juanfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:09', '2020-11-01 10:38:09'),
(580, 72, 'Johnville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:10', '2020-11-01 10:38:10'),
(581, 57, 'Huberville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:11', '2020-11-01 10:38:11'),
(582, 31, 'Huynhtown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:12', '2020-11-01 10:38:12'),
(583, 2, 'Christopherborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:13', '2020-11-01 10:38:13'),
(584, 83, 'Fisherport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:14', '2020-11-01 10:38:14'),
(585, 40, 'Laceymouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:15', '2020-11-01 10:38:15'),
(586, 84, 'New Taylor', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:16', '2020-11-01 10:38:16'),
(587, 103, 'Port Todd', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:17', '2020-11-01 10:38:17'),
(588, 83, 'Port Bruce', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:18', '2020-11-01 10:38:18'),
(589, 67, 'West Kristin', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:19', '2020-11-01 10:38:19'),
(590, 42, 'East Austin', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:20', '2020-11-01 10:38:20'),
(591, 68, 'South Collin', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:21', '2020-11-01 10:38:21'),
(592, 83, 'New Dawn', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:22', '2020-11-01 10:38:22'),
(593, 32, 'West Calebfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:23', '2020-11-01 10:38:23'),
(594, 29, 'Lake Michaelfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:24', '2020-11-01 10:38:24'),
(595, 53, 'New Joshua', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:25', '2020-11-01 10:38:25'),
(596, 4, 'East Brian', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:26', '2020-11-01 10:38:26'),
(597, 91, 'Penningtonfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:27', '2020-11-01 10:38:27'),
(598, 95, 'Lake Krystal', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:28', '2020-11-01 10:38:28'),
(599, 28, 'West Jonathanport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:29', '2020-11-01 10:38:29'),
(600, 45, 'Jamesshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:30', '2020-11-01 10:38:30'),
(601, 63, 'Williefort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:31', '2020-11-01 10:38:31'),
(602, 19, 'Whiteburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:32', '2020-11-01 10:38:32'),
(603, 10, 'Dawnhaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:33', '2020-11-01 10:38:33'),
(604, 37, 'Brooksmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:34', '2020-11-01 10:38:34'),
(605, 111, 'Cunninghambury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:35', '2020-11-01 10:38:35'),
(606, 61, 'West Andrew', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:36', '2020-11-01 10:38:36'),
(607, 121, 'South Katherine', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:37', '2020-11-01 10:38:37'),
(608, 55, 'Darrellfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:38', '2020-11-01 10:38:38'),
(609, 78, 'South Michaelborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:39', '2020-11-01 10:38:39'),
(610, 47, 'Lake Tinamouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:40', '2020-11-01 10:38:40'),
(611, 114, 'Stoneshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:41', '2020-11-01 10:38:41'),
(612, 113, 'Lake Courtneyborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:42', '2020-11-01 10:38:42'),
(613, 10, 'Lake Christopherberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:43', '2020-11-01 10:38:43'),
(614, 18, 'Jamesbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:44', '2020-11-01 10:38:44'),
(615, 54, 'Jordanfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:45', '2020-11-01 10:38:45'),
(616, 117, 'North Ethan', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:46', '2020-11-01 10:38:46'),
(617, 94, 'Leachchester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:47', '2020-11-01 10:38:47'),
(618, 51, 'Stevenstad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:48', '2020-11-01 10:38:48'),
(619, 62, 'Port Edward', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:49', '2020-11-01 10:38:49'),
(620, 35, 'Loganburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:50', '2020-11-01 10:38:50'),
(621, 70, 'Deborahview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:51', '2020-11-01 10:38:51'),
(622, 91, 'Burnsmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:52', '2020-11-01 10:38:52'),
(623, 116, 'Garrettborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:53', '2020-11-01 10:38:53'),
(624, 115, 'Nicolebury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:54', '2020-11-01 10:38:54'),
(625, 102, 'New Rickyside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:55', '2020-11-01 10:38:55'),
(626, 31, 'Hollandbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:56', '2020-11-01 10:38:56'),
(627, 62, 'Blairville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:57', '2020-11-01 10:38:57'),
(628, 119, 'Alexandermouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:58', '2020-11-01 10:38:58'),
(629, 102, 'Rebeccaberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:38:59', '2020-11-01 10:38:59'),
(630, 70, 'New Emily', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:00', '2020-11-01 10:39:00'),
(631, 7, 'Williamfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:01', '2020-11-01 10:39:01'),
(632, 69, 'New Dustinside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:02', '2020-11-01 10:39:02'),
(633, 3, 'Emilyfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:03', '2020-11-01 10:39:03'),
(634, 112, 'Williamburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:05', '2020-11-01 10:39:05'),
(635, 95, 'Charlotteton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:06', '2020-11-01 10:39:06'),
(636, 66, 'South Yvonneville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:07', '2020-11-01 10:39:07'),
(637, 18, 'Johnsonfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:08', '2020-11-01 10:39:08'),
(638, 93, 'Campbelltown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:09', '2020-11-01 10:39:09'),
(639, 18, 'New Alexandraland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:10', '2020-11-01 10:39:10'),
(640, 7, 'Cathytown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:11', '2020-11-01 10:39:11'),
(641, 122, 'West Sherrihaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:12', '2020-11-01 10:39:12'),
(642, 33, 'Gainesbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:13', '2020-11-01 10:39:13'),
(643, 11, 'Brittanyburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:14', '2020-11-01 10:39:14'),
(644, 12, 'Jessicaside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:15', '2020-11-01 10:39:15'),
(645, 20, 'Lake Michellehaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:16', '2020-11-01 10:39:16'),
(646, 2, 'North Justin', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:17', '2020-11-01 10:39:17'),
(647, 89, 'North John', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:18', '2020-11-01 10:39:18'),
(648, 110, 'Rossfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:19', '2020-11-01 10:39:19'),
(649, 58, 'Michaelview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:20', '2020-11-01 10:39:20'),
(650, 115, 'Lake Mark', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:21', '2020-11-01 10:39:21'),
(651, 117, 'New Dustin', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:22', '2020-11-01 10:39:22'),
(652, 41, 'Nicholsmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:23', '2020-11-01 10:39:23'),
(653, 116, 'West William', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:24', '2020-11-01 10:39:24'),
(654, 20, 'Aaronport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:25', '2020-11-01 10:39:25'),
(655, 91, 'Morrischester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:26', '2020-11-01 10:39:26'),
(656, 41, 'Clarketon', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:27', '2020-11-01 10:39:27'),
(657, 27, 'East Albert', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:28', '2020-11-01 10:39:28'),
(658, 23, 'Brandystad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:29', '2020-11-01 10:39:29'),
(659, 26, 'New Todd', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:30', '2020-11-01 10:39:30'),
(660, 30, 'Mcdowellchester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:31', '2020-11-01 10:39:31'),
(661, 36, 'New Christina', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:32', '2020-11-01 10:39:32'),
(662, 5, 'East Daniel', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:33', '2020-11-01 10:39:33'),
(663, 72, 'Toniview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:34', '2020-11-01 10:39:34'),
(664, 13, 'West Amandaland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:35', '2020-11-01 10:39:35'),
(665, 102, 'Ritaton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:36', '2020-11-01 10:39:36'),
(666, 83, 'Kevinstad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:37', '2020-11-01 10:39:37'),
(667, 111, 'Port Donnafort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:38', '2020-11-01 10:39:38'),
(668, 73, 'Lake Shelby', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:39', '2020-11-01 10:39:39'),
(669, 104, 'West Benjaminshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:40', '2020-11-01 10:39:40'),
(670, 103, 'South Isaac', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:41', '2020-11-01 10:39:41'),
(671, 115, 'South Apriltown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:42', '2020-11-01 10:39:42'),
(672, 47, 'Port Williamburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:43', '2020-11-01 10:39:43'),
(673, 114, 'Jonathanchester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:44', '2020-11-01 10:39:44'),
(674, 97, 'Daisybury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:45', '2020-11-01 10:39:45'),
(675, 72, 'North Danielberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:46', '2020-11-01 10:39:46'),
(676, 55, 'Lake Amandastad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:47', '2020-11-01 10:39:47'),
(677, 87, 'Jenniferside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:48', '2020-11-01 10:39:48'),
(678, 13, 'Lake Sandra', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:49', '2020-11-01 10:39:49'),
(679, 22, 'East Nicolemouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:50', '2020-11-01 10:39:50'),
(680, 96, 'East Erikaview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:51', '2020-11-01 10:39:51'),
(681, 83, 'Matthewborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:52', '2020-11-01 10:39:52'),
(682, 54, 'Katherineport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:53', '2020-11-01 10:39:53'),
(683, 8, 'Smithborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:54', '2020-11-01 10:39:54'),
(684, 90, 'Pamelabury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:55', '2020-11-01 10:39:55'),
(685, 47, 'Jeffreystad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:56', '2020-11-01 10:39:56'),
(686, 1, 'South Davidshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:57', '2020-11-01 10:39:57'),
(687, 119, 'Bruceville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:58', '2020-11-01 10:39:58'),
(688, 92, 'West Michellehaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:39:59', '2020-11-01 10:39:59'),
(689, 53, 'East Robertchester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:01', '2020-11-01 10:40:01'),
(690, 83, 'Ricetown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:02', '2020-11-01 10:40:02'),
(691, 65, 'Michaelport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:03', '2020-11-01 10:40:03'),
(692, 58, 'Jeffreyport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:04', '2020-11-01 10:40:04'),
(693, 85, 'Humphreyport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:05', '2020-11-01 10:40:05'),
(694, 63, 'East Amandachester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:06', '2020-11-01 10:40:06'),
(695, 82, 'Teresabury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:07', '2020-11-01 10:40:07'),
(696, 85, 'Nguyenside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:08', '2020-11-01 10:40:08'),
(697, 20, 'East Taramouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:09', '2020-11-01 10:40:09'),
(698, 23, 'North Jenniferfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:10', '2020-11-01 10:40:10'),
(699, 54, 'Evansberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:11', '2020-11-01 10:40:11'),
(700, 85, 'West Williamland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:12', '2020-11-01 10:40:12'),
(701, 118, 'New Lisaburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:13', '2020-11-01 10:40:13'),
(702, 22, 'Lake Lisa', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:14', '2020-11-01 10:40:14'),
(703, 50, 'Lake John', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:15', '2020-11-01 10:40:15'),
(704, 23, 'Pughshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:16', '2020-11-01 10:40:16'),
(705, 111, 'Gonzalezfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:17', '2020-11-01 10:40:17'),
(706, 88, 'East Kevinton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:18', '2020-11-01 10:40:18'),
(707, 48, 'Lauraborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:19', '2020-11-01 10:40:19'),
(708, 12, 'Danielburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:20', '2020-11-01 10:40:20'),
(709, 124, 'Elizabethland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:21', '2020-11-01 10:40:21'),
(710, 53, 'Georgemouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:22', '2020-11-01 10:40:22'),
(711, 41, 'Allenfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:23', '2020-11-01 10:40:23'),
(712, 94, 'New Kaylaview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:24', '2020-11-01 10:40:24'),
(713, 37, 'West Barryport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:25', '2020-11-01 10:40:25'),
(714, 63, 'New Stacieview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:26', '2020-11-01 10:40:26'),
(715, 11, 'North Jessicatown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:27', '2020-11-01 10:40:27'),
(716, 35, 'Smithville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:28', '2020-11-01 10:40:28'),
(717, 14, 'West Summer', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:29', '2020-11-01 10:40:29'),
(718, 44, 'Barkerburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:30', '2020-11-01 10:40:30'),
(719, 1, 'Thomasburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:31', '2020-11-01 10:40:31'),
(720, 32, 'Zamorafort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:32', '2020-11-01 10:40:32'),
(721, 42, 'Parksfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:33', '2020-11-01 10:40:33'),
(722, 99, 'Jamesfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:34', '2020-11-01 10:40:34'),
(723, 34, 'Port Jacob', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:35', '2020-11-01 10:40:35'),
(724, 32, 'South Gloriashire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:36', '2020-11-01 10:40:36'),
(725, 17, 'New Brian', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:37', '2020-11-01 10:40:37'),
(726, 40, 'Benitezland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:38', '2020-11-01 10:40:38'),
(727, 43, 'Catherineview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:39', '2020-11-01 10:40:39'),
(728, 99, 'New Jose', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:40', '2020-11-01 10:40:40'),
(729, 123, 'Jacobsport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:41', '2020-11-01 10:40:41'),
(730, 61, 'Conradport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:42', '2020-11-01 10:40:42'),
(731, 60, 'Youngborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:43', '2020-11-01 10:40:43'),
(732, 42, 'Millerview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:44', '2020-11-01 10:40:44'),
(733, 70, 'Lake Kristenchester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:45', '2020-11-01 10:40:45'),
(734, 51, 'Sarahburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:46', '2020-11-01 10:40:46'),
(735, 65, 'Laneburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:47', '2020-11-01 10:40:47'),
(736, 118, 'Kimberlyfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:48', '2020-11-01 10:40:48'),
(737, 10, 'East Dawn', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:49', '2020-11-01 10:40:49'),
(738, 31, 'South Amandaville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:50', '2020-11-01 10:40:50'),
(739, 40, 'Haleyshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:51', '2020-11-01 10:40:51'),
(740, 28, 'Shannonmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:52', '2020-11-01 10:40:52'),
(741, 76, 'Greenbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:53', '2020-11-01 10:40:53'),
(742, 18, 'Port Lindsay', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:54', '2020-11-01 10:40:54'),
(743, 19, 'Dawnport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:56', '2020-11-01 10:40:56'),
(744, 91, 'West Roy', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:57', '2020-11-01 10:40:57'),
(745, 89, 'Brianfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:58', '2020-11-01 10:40:58'),
(746, 2, 'Lake Masonton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:40:59', '2020-11-01 10:40:59'),
(747, 105, 'Russobury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:00', '2020-11-01 10:41:00'),
(748, 23, 'Emilyland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:01', '2020-11-01 10:41:01'),
(749, 103, 'East David', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:02', '2020-11-01 10:41:02'),
(750, 53, 'Zacharyborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:03', '2020-11-01 10:41:03'),
(751, 28, 'Williamsville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:04', '2020-11-01 10:41:04'),
(752, 94, 'West Mary', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:05', '2020-11-01 10:41:05'),
(753, 88, 'Contrerasmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:06', '2020-11-01 10:41:06'),
(754, 19, 'Lake Ashleeborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:07', '2020-11-01 10:41:07'),
(755, 21, 'Thomaschester', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:08', '2020-11-01 10:41:08'),
(756, 81, 'Morenostad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:09', '2020-11-01 10:41:09'),
(757, 98, 'Nobleland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:10', '2020-11-01 10:41:10'),
(758, 37, 'East Oscar', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:11', '2020-11-01 10:41:11'),
(759, 90, 'South Elizabethview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:12', '2020-11-01 10:41:12'),
(760, 109, 'Kevinville', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:13', '2020-11-01 10:41:13'),
(761, 110, 'Garymouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:14', '2020-11-01 10:41:14'),
(762, 73, 'New Tricia', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:15', '2020-11-01 10:41:15'),
(763, 10, 'East Connie', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:16', '2020-11-01 10:41:16'),
(764, 123, 'Jenniferborough', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:17', '2020-11-01 10:41:17'),
(765, 103, 'North Larry', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:18', '2020-11-01 10:41:18'),
(766, 11, 'Jonestown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:19', '2020-11-01 10:41:19'),
(767, 111, 'North Peterstad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:20', '2020-11-01 10:41:20'),
(768, 123, 'South Jamieside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:21', '2020-11-01 10:41:21'),
(769, 1, 'East Michelle', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:22', '2020-11-01 10:41:22'),
(770, 62, 'North Bobby', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:23', '2020-11-01 10:41:23'),
(771, 32, 'Katrinastad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:24', '2020-11-01 10:41:24'),
(772, 100, 'Lake Christopher', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:25', '2020-11-01 10:41:25'),
(773, 88, 'North Robert', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:26', '2020-11-01 10:41:26'),
(774, 91, 'West Danielle', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:27', '2020-11-01 10:41:27'),
(775, 35, 'Coreyfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:28', '2020-11-01 10:41:28'),
(776, 98, 'Ramirezmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:29', '2020-11-01 10:41:29'),
(777, 30, 'Lake Bryan', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:30', '2020-11-01 10:41:30'),
(778, 54, 'Jessicaport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:31', '2020-11-01 10:41:31'),
(779, 81, 'New Danielton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:32', '2020-11-01 10:41:32'),
(780, 22, 'Marshmouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:33', '2020-11-01 10:41:33'),
(781, 71, 'North Brian', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:34', '2020-11-01 10:41:34'),
(782, 81, 'Nortonbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:35', '2020-11-01 10:41:35'),
(783, 44, 'Davidfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:36', '2020-11-01 10:41:36'),
(784, 20, 'Lake Randallfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:37', '2020-11-01 10:41:37'),
(785, 53, 'Timothyside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:38', '2020-11-01 10:41:38'),
(786, 81, 'East Vanessa', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:39', '2020-11-01 10:41:39'),
(787, 26, 'Crawfordport', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:40', '2020-11-01 10:41:40'),
(788, 105, 'Reillyberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:41', '2020-11-01 10:41:41'),
(789, 111, 'Scotthaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:42', '2020-11-01 10:41:42'),
(790, 37, 'Richardbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:43', '2020-11-01 10:41:43'),
(791, 120, 'Garciaberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:44', '2020-11-01 10:41:44'),
(792, 25, 'New Molly', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:45', '2020-11-01 10:41:45'),
(793, 47, 'East Tonya', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:46', '2020-11-01 10:41:46'),
(794, 90, 'North Teresa', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:47', '2020-11-01 10:41:47'),
(795, 80, 'Greenside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:48', '2020-11-01 10:41:48'),
(796, 95, 'Tiffanyfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:50', '2020-11-01 10:41:50'),
(797, 63, 'Walterview', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:51', '2020-11-01 10:41:51'),
(798, 31, 'South Garybury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:52', '2020-11-01 10:41:52'),
(799, 107, 'North Juanhaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:53', '2020-11-01 10:41:53'),
(800, 101, 'North Jessica', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:54', '2020-11-01 10:41:54'),
(801, 88, 'Lake Brittanyburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:55', '2020-11-01 10:41:55'),
(802, 88, 'Lake Emilystad', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:56', '2020-11-01 10:41:56'),
(803, 88, 'Mitchellland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:57', '2020-11-01 10:41:57'),
(804, 74, 'North Jenniferland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:58', '2020-11-01 10:41:58'),
(805, 105, 'East Amanda', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:41:59', '2020-11-01 10:41:59'),
(806, 62, 'West Jennifer', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:00', '2020-11-01 10:42:00'),
(807, 24, 'Port Pamela', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:01', '2020-11-01 10:42:01'),
(808, 71, 'Karlfurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:02', '2020-11-01 10:42:02'),
(809, 1, 'North Markshire', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:03', '2020-11-01 10:42:03'),
(810, 22, 'Adamsland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:04', '2020-11-01 10:42:04'),
(811, 6, 'Rowlandfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:05', '2020-11-01 10:42:05'),
(812, 19, 'New Brendan', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:06', '2020-11-01 10:42:06'),
(813, 102, 'North Davidtown', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:07', '2020-11-01 10:42:07'),
(814, 67, 'Oliviafurt', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:08', '2020-11-01 10:42:08'),
(815, 7, 'Brownburgh', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:09', '2020-11-01 10:42:09'),
(816, 12, 'Port Michael', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:10', '2020-11-01 10:42:10'),
(817, 95, 'North Rhonda', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:11', '2020-11-01 10:42:11'),
(818, 63, 'Wayneberg', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:12', '2020-11-01 10:42:12'),
(819, 47, 'Port Ronaldhaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:13', '2020-11-01 10:42:13'),
(820, 13, 'Morganhaven', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:14', '2020-11-01 10:42:14'),
(821, 46, 'North Robertfort', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:15', '2020-11-01 10:42:15'),
(822, 112, 'Petersonside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:16', '2020-11-01 10:42:16'),
(823, 26, 'Bushton', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:17', '2020-11-01 10:42:17'),
(824, 81, 'Tammymouth', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:18', '2020-11-01 10:42:18'),
(825, 115, 'Bradbury', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:19', '2020-11-01 10:42:19'),
(826, 5, 'Danielland', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:20', '2020-11-01 10:42:20'),
(827, 1, 'Dorisside', NULL, NULL, NULL, NULL, NULL, NULL, '2020-11-01 10:42:21', '2020-11-01 10:42:21');
