-- Apparently UDF for check constraints are also problematic:
-- https://dba.stackexchange.com/questions/12779/how-are-my-sql-server-constraints-being-bypassed
-- Otherwise

DROP FUNCTION IF EXISTS Country_population;
DELIMITER ;;
CREATE FUNCTION Country_population(_cont_id INTEGER) RETURNS INTEGER DETERMINISTIC
BEGIN
  DECLARE country_sum INTEGER;

  SET country_sum = (SELECT SUM(population) FROM country WHERE cont_id = _cont_id);

  RETURN (
      SELECT country_sum <= population FROM continent WHERE id = _cont_id
  );
END
;;
DELIMITER ;

ALTER TABLE continent ADD CONSTRAINT CHK_cont_populations CHECK (Country_population(id));






-- Validation needs to be done via SP, can have either a trigger before update/insert to call the valiation SP, or have an insert/update SP which also does the validation.
-- https://www.mysqltutorial.org/mysql-check-constraint-emulation/


-- sp for all validation rules
-- ommited because of overcomplexity and cannot have dynamic sql in trigger
-- improvement in refactoring code
-- country case stll needs work

DROP PROCEDURE IF EXISTS `sp_validate`;
DELIMITER $
CREATE PROCEDURE `sp_validate`(IN _table VARCHAR(127), IN attribute VARCHAR(127), IN parent_id INTEGER, IN id INTEGER, IN new_value INTEGER)
BEGIN

    SET @parent_id = parent_id;
    SET @id = id;
    SET @attribute_constraint_lower = '';
    SET @attribute_constraint_upper = '';


    CASE _table
    WHEN 'CONTINENT' THEN

        SET @attribute_constraint_lower_query = CONCAT("SELECT IFNULL(SUM(", attribute, "), 0) INTO @attribute_constraint_lower FROM country WHERE cont_id = @id");
        SET @desired_attribute_value = new_value;
        SET @attribute_constraint_upper_query = 'SELECT NULL INTO @attribute_constraint_upper';


    WHEN 'COUNTRY' THEN

        -- return the attribute of parent which constraints the table value
        -- eg return population of a continent if a new country with a set population is to be inserted/updated
        SET @attribute_constraint_upper = '';
        SET @attribute_constraint_upper_query = CONCAT("SELECT IFNULL(SUM(", attribute, "), 0) INTO @attribute_constraint_upper FROM continent WHERE id = @parent_id");

        PREPARE attribute_constraint_query FROM @attribute_constraint_query;
        EXECUTE attribute_constraint_query;
        DEALLOCATE PREPARE attribute_constraint_query;

        -- return the new sum of the attribute for the table
        -- eg return the new sum of populations of cities assuming the city is inserted/updated
        SET @attribute_sum = '';
        SET @sum_attribute_query = CONCAT("SELECT IFNULL(SUM(", attribute, "), 0) + ", new_value, " INTO @attribute_sum FROM city WHERE country_id = @parent_id AND id != @id");

        PREPARE sum_attribute_query FROM @sum_attribute_query;
        EXECUTE sum_attribute_query;
        DEALLOCATE PREPARE sum_attribute_query;

        IF (new_value < @attribute_constraint_lower) OR (@attribute_constraint_upper < new_value) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'check constraint failed because country attribute is not consistent with continent of city.';
        END IF;


    WHEN 'CITY' THEN

        -- return the attribute of parent which constraints the table value
        -- eg return population of a country if a new city with a set population is to be inserted/updated
        SET @attribute_constraint_upper_query = CONCAT("SELECT IFNULL(SUM(", attribute, "), 0) INTO @attribute_constraint_upper FROM country WHERE id = @parent_id");
        SET @attribute_constraint_lower_query = 'SELECT NULL INTO @attribute_constraint_lower';

        -- return the new sum of the attribute for the table
        -- eg return the new sum of populations of cities assuming the city is inserted/updated
        SET @desired_attribute_value_query = CONCAT("SELECT IFNULL(SUM(", attribute, "), 0) + ", new_value, " INTO @desired_attribute_value FROM city WHERE country_id = @parent_id AND id != @id");

        PREPARE desired_attribute_value_query FROM @desired_attribute_value_query;
        EXECUTE desired_attribute_value_query;
        DEALLOCATE PREPARE desired_attribute_value_query;

    END CASE;



    PREPARE attribute_constraint_lower_query FROM @attribute_constraint_lower_query;
    EXECUTE attribute_constraint_lower_query;
    DEALLOCATE PREPARE attribute_constraint_lower_query;

    PREPARE attribute_constraint_upper_query FROM @attribute_constraint_upper_query;
    EXECUTE attribute_constraint_upper_query;
    DEALLOCATE PREPARE attribute_constraint_upper_query;

    -- validate that the new value is consistent with the constraints
    IF (@attribute_constraint_lower > @desired_attribute_value) OR (@desired_attribute_value > @attribute_constraint_upper) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'check constraint failed because intended attribute value is inconsistent.';
    END IF;

END$
DELIMITER ;
