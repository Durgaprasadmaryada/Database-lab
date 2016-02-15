-- australia bowling , india batting

DROP DATABASE IF EXISTS assignment4_final_1;
CREATE DATABASE assignment4_final_1;

USE assignment4_final_1;


CREATE FUNCTION SPLIT_STR(
  x VARCHAR(255),
  delim VARCHAR(12),
  pos INT
)
RETURNS VARCHAR(255)
RETURN REPLACE(SUBSTRING(SUBSTRING_INDEX(x, delim, pos),
       LENGTH(SUBSTRING_INDEX(x, delim, pos -1)) + 1),
       delim, '');



CREATE TABLE commentry(
comment varchar(500)
);

-- change the address of the file
LOAD DATA LOCAL INFILE '/home/mdvpr/Documents/Databases lab/assignment4_130101045/dbms1.txt' into TABLE commentry FIELDS TERMINATED BY '\n' LINES TERMINATED BY '\r\n';

ALTER TABLE commentry ADD id int auto_increment PRIMARY KEY;

select max(id) from commentry into @nrows;

CREATE TABLE data_comm(
ball varchar(10),
bowler varchar(50),
batsmen varchar(50),
ball_status varchar(50),
runs int NOT NULL,
balls int NOT NULL,
fours int NOT NULL,
sixes int NOT NULL,
noruns int NOT NULL,
wicket int NOT NULL,
wides int NOT NULL,
bat_runs int NOT NULL,
bat_balls int NOT NULL
);

CREATE TABLE india_score (
    sid int NOT NULL AUTO_INCREMENT PRIMARY KEY,
    batsman varchar(255),
    balls int DEFAULT 0,
    runs int DEFAULT 0,
    fours int DEFAULT 0,
    sixes int DEFAULT 0,
    UNIQUE (batsman )
);

CREATE TABLE australia_bowling(
	sid int NOT NULL AUTO_INCREMENT PRIMARY KEY,
	bowler varchar(255),
	ballsbowled int DEFAULT 0,
	runsgiven int DEFAULT 0,
	oversbowled decimal(3,1) DEFAULT 0,
	Maidensbowled int DEFAULT 0,	
	wicketstaken int DEFAULT 0,
	economy decimal(3,2),
	zeroesbowled int default 0,
	foursgiven int default 0,
	sixesgiven int default 0,
	wides int default 0,
	UNIQUE(bowler )
);


DELIMITER $$
CREATE TRIGGER indiascore BEFORE INSERT ON data_comm
    FOR EACH ROW
    BEGIN
        INSERT IGNORE INTO india_score
        SET batsman = NEW.batsmen;
 	
        UPDATE india_score
        SET balls = balls + NEW.bat_balls,
            runs = runs + NEW.bat_runs,
            fours = fours + NEW.fours,
            sixes = sixes + NEW.sixes
        WHERE batsman = NEW.batsmen;

    END;
$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER indiabowl AFTER INSERT ON data_comm
FOR EACH ROW
BEGIN
	INSERT IGNORE INTO australia_bowling
	SET bowler = NEW.bowler;

	UPDATE australia_bowling
	SET ballsbowled = ballsbowled + NEW.balls,
	    runsgiven = runsgiven + NEW.runs,	
 	    zeroesbowled = zeroesbowled + NEW.noruns,
	    wicketstaken = wicketstaken + NEW.wicket,
	    foursgiven = foursgiven + NEW.fours,
            sixesgiven = sixesgiven + NEW.sixes,
	    wides = wides + NEW.wides
	WHERE bowler = NEW.bowler;
	END;

$$
DELIMITER ;

SET @extras = 0;
DELIMITER $$  
CREATE PROCEDURE parsing()
BEGIN
 DECLARE a INT Default 0 ;
        simple_loop: LOOP
          SET a=a+1;
   SELECT comment from commentry WHERE id=a into @ourstring;
   SELECT SPLIT_STR(SPLIT_STR(@ourstring,',',1),' to ',2) into @bat;
   SELECT SPLIT_STR(@ourstring,',',2) into @status;
   SET @runs = 0;
   SET @fours = 0;
   SET @sixes = 0;
   SET @onlyforteam = 0;
   SET @balls = 1;
   SET @norun = 0;
   SET @wicket = 0;
   SET @wide = 0;
   SET @bat_runs = 0;
   SET @bat_balls = 1;
   IF @status = ' no run' then SET @runs=0; SET @bat_runs=0; SET @norun=1; 
   ELSEIF @status = ' 1 run' then SET @runs=1; SET @bat_runs=1; 
   ELSEIF @status = ' 2 runs' then SET @runs=2; SET @bat_runs=2; 
   ELSEIF @status = ' 3 runs' then SET @runs=3; SET @bat_runs=3;
   ELSEIF @status = ' FOUR' then SET @runs=4; SET @fours=1; SET @bat_runs=4;
   ELSEIF @status = ' SIX' then SET @runs=6; SET @sixes=1; SET @bat_runs=6;
   ELSEIF @status = ' OUT' then SET @wicket=1;
   ELSEIF @status = ' 1 wide' then SET @wide=1; SET @balls=1; SET @runs=1; SET @bat_runs=0; SET @bat_balls=0; SET @extras = @extras+1;
   ELSEIF @status = ' 2 wides' then SET @wide=2; SET @balls=2;SET @runs=2; SET @bat_runs=0; SET @bat_balls=0; SET @extras = @extras+2;
   END IF;

   SELECT SPLIT_STR(SPLIT_STR(@ourstring,' to ',1),'-',2) into @bowl;

   SELECT SPLIT_STR(SPLIT_STR(@ourstring,' to ',1),'-',1) into @ballinover;

   INSERT INTO data_comm values(@ballinover,@bowl,@bat,@status,@runs,@balls,@fours,@sixes,@norun,@wicket,@wide,@bat_runs,@bat_balls);
  
  IF a=307 THEN
              LEAVE simple_loop;
          END IF;
      END LOOP simple_loop;
  END $$

DELIMITER ;


CALL parsing();

ALTER TABLE india_score ADD strikerate decimal(6,3);
UPDATE india_score SET strikerate = runs/balls*100;

UPDATE australia_bowling SET oversbowled = ((ballsbowled-wides)/6) - (((ballsbowled-wides)/6)%1) + 0.1*((ballsbowled - wides)%6);
UPDATE australia_bowling SET economy = runsgiven/oversbowled;

select * from india_score;
select @extras;
select * from australia_bowling;










