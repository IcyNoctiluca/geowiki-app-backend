## DB Configurations and Implementation process

Introduced here is the DB implementation, mechanisms for triggers, and the stored procedures for data validation before updates to attributes are performed.

It was attempted to use a SQLite DB to contain the data. This was to avoid setting up a SQL server, writing users and permissions etc., thereby making the process lighter.
However SQLite lacks features such as high concurrency, which would be necessary for scalability for this application. Furthermore it does not have features such as
stored procedures and functions, making data validation clunky to implement. Consequently a MySQL server was chosen.  

For validation checks, it was initially tried to have a check constraint written into the table schema which would call a UD function to validate data (see appended code).
According to [1] however, UDFs in check constraints are bypassed, making this design non-workable. 

Therefore triggers were implemented. ```INSERT``` and ```UPDATE``` triggers are implemented in the country
and city tables, while only ```UPDATE``` trigger applies to the continent table (since an insertion to continent means there are no underlying country/city entries with that foreign key).
```DELETE``` triggers were not needed as no constraints can be violated, as ```ON DELETE CASCADE``` is used for foreign keys. All triggers are before any data manipulation.

Initially it was tried to have a single stored procedure encompassing all of the validation rules to be called by all of the triggers. (See SP below, for example: ```sp_validate('CITY', 'area', <parent_id>, <id>, <new_value>);```) 
This would have however, required dynamic SQL, which is not permitted inside a trigger, so instead separate SPs were made to validate each table's attribute as in [2].
Unfortunately this required a lot of SPs, each containing similar code blocks, but it does give a high level of granularity.

All validation checks operate similarly. For example if a client requests the area of a country to be updated,
it queries the continent population (continent is a foreign key of the country), and then the sum of the underlying cities' population based on an index.
All queries are index-based to reduce table locking time. If a constraint is violated, an error is thrown.


#### Appended abandoned code

###### Check constraint on tables involving UDF
```
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
```

###### SP to validate all attribute changes to all tables
```
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
```


#### References 

[1] https://dba.stackexchange.com/questions/12779/how-are-my-sql-server-constraints-being-bypassed

[2] https://www.mysqltutorial.org/mysql-check-constraint-emulation/
