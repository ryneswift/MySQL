CREATE SCHEMA lichess_data;



CREATE TABLE str_list_2013 (
    UTCDate VARCHAR(50),
    White VARCHAR(50),
    Black VARCHAR(50),
    Variant VARCHAR(50),
    TimeControl VARCHAR(50),
    ECO VARCHAR(50),
    Termination VARCHAR(50)
);



CREATE TABLE str_list_2014 (
    UTCDate VARCHAR(50),
    White VARCHAR(50),
    Black VARCHAR(50),
    Variant VARCHAR(50),
    TimeControl VARCHAR(50),
    ECO VARCHAR(50),
    Termination VARCHAR(50)
);


CREATE TABLE int_array_2013 (
    Result INT,
    White_Elo INT,
    Black_Elo INT,
    Elo_Difference INT,
    Fortieth_FEN_Eval INT,
    sum_eval INT,
    total_half_moves INT
);


CREATE TABLE int_array_2014 (
    Result INT,
    White_Elo INT,
    Black_Elo INT,
    Elo_Difference INT,
    Fortieth_FEN_Eval INT,
    sum_eval INT,
    total_half_moves INT
);


/*
Necessary to split the 2014 files into multiple parts because the SQL connection kept timing out for larger files, 
despite changes made in the settings.

Each chess game has its information split into two tables, the int_array and the str_list tables.
Each row of these tables corresponds to the same chess game, meaning that the rows are aligned across the two tables.
*/



LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.0/Uploads/merged_2013_int_array.csv'
INTO TABLE int_array_2013
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
; 




LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.0/Uploads/merged_2013_str_list.csv'
INTO TABLE str_list_2013
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
; 





LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.0/Uploads/merged_2014_int_array_part1.csv'
INTO TABLE int_array_2014
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
; 


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.0/Uploads/merged_2014_int_array_part2.csv'
INTO TABLE int_array_2014
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
; 


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.0/Uploads/merged_2014_int_array_part3.csv'
INTO TABLE int_array_2014
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
; 


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.0/Uploads/merged_2014_int_array_part4.csv'
INTO TABLE int_array_2014
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
; 



LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.0/Uploads/merged_2014_str_list_part1.csv'
INTO TABLE str_list_2014
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
; 


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.0/Uploads/merged_2014_str_list_part2.csv'
INTO TABLE str_list_2014
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
; 


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.0/Uploads/merged_2014_str_list_part3.csv'
INTO TABLE str_list_2014
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
; 


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.0/Uploads/merged_2014_str_list_part4.csv'
INTO TABLE str_list_2014
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
; 


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.0/Uploads/merged_2014_str_list_part5.csv'
INTO TABLE str_list_2014
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
; 


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.0/Uploads/merged_2014_str_list_part6.csv'
INTO TABLE str_list_2014
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
; 


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.0/Uploads/merged_2014_str_list_part7.csv'
INTO TABLE str_list_2014
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
; 


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.0/Uploads/merged_2014_str_list_part8.csv'
INTO TABLE str_list_2014
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
; 








SELECT 
	COUNT(*) AS row_count
FROM 
	int_array_2014;


SELECT 
	COUNT(*) AS row_count
FROM 
	str_list_2014;




#Our data is split into multiple tables, but we want to combine the data by year into tables.
#The following queries achieve this. Note that it was necessary to limit the size of the tables because
#the mySQL session would timeout from the query taking too long, due to the tables having many rows.





DROP TABLE int_array_2014_shortened;
DROP TABLE str_list_2014_shortened;


CREATE TABLE int_array_2013_shortened AS
SELECT *
FROM int_array_2013
LIMIT 500000;


CREATE TABLE str_list_2013_shortened AS
SELECT *
FROM str_list_2013
LIMIT 500000;



CREATE TABLE int_array_2014_shortened AS
SELECT *
FROM int_array_2014
LIMIT 500000;



CREATE TABLE str_list_2014_shortened AS
SELECT *
FROM str_list_2014
LIMIT 500000;






SET SQL_SAFE_UPDATES = 0;
    

#Adding in columns which contain the row number so we can merge the tables together by them
ALTER TABLE int_array_2013_shortened ADD COLUMN row_num INT;
ALTER TABLE str_list_2013_shortened ADD COLUMN row_no INT;    
    
#alter table int_array_2014_shortened add column row_num int;
#alter table str_list_2014_shortened add column row_no int;



SET @row_num = 0;

UPDATE int_array_2013_shortened
SET row_num = (@row_num := @row_num + 1)
ORDER BY (SELECT NULL);


SET @row_no = 0;

UPDATE str_list_2013_shortened
SET row_no = (@row_no := @row_no + 1)
ORDER BY (SELECT NULL);




SET @row_num = 0;

UPDATE int_array_2014_shortened
SET row_num = (@row_num := @row_num + 1)
ORDER BY (SELECT NULL);


SET @row_no = 0;

UPDATE str_list_2014_shortened
SET row_no = (@row_no := @row_no + 1)
ORDER BY (SELECT NULL);




#Creating our merged tables, which contain all the information of a chess game

CREATE TABLE merged_2013_shortened AS
SELECT 
    str_list.*,
    int_arr.*
FROM 
    str_list_2013_shortened AS str_list
INNER JOIN 
    int_array_2013_shortened AS int_arr ON str_list.row_no = int_arr.row_num;
    
    


CREATE TABLE merged_2014_shortened AS
SELECT 
    str_list.*,
    int_arr.*
FROM 
    str_list_2014_shortened AS str_list
INNER JOIN 
    int_array_2014_shortened AS int_arr ON str_list.row_no = int_arr.row_num;


