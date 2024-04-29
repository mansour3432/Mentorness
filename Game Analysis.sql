-- Explore the Level Table
SELECT * 
FROM [game].[dbo].[level]

----------------------------------------------------------------------------------------------

--Explore the Player Table
SELECT * 
FROM [game].[dbo].[player] 



-- Q1) Extract P_ID,Dev_ID,PName and Difficulty_level of all players 
-- at level 0

--Show all player at level 0 and the difficulty level
SELECT l.P_Id,
       Dev_ID,
       PName,
       Difficulty
FROM [game].[dbo].[level] l
JOIN [game].[dbo].[player] p
  ON l.P_ID = p.P_ID
WHERE l.Level = 0

----------------------------------------------------------------------------------------------



-- Q2) Find Level1_code wise Avg_Kill_Count where lives_earned is 2 and atleast
-- 3 stages are crossed

--Show avg_kill_count for L1_code

SELECT L1_code,
       AVG(Kill_Count) as Avg_Kill_Count
FROM [game].[dbo].[level] l
JOIN [game].[dbo].[player] p
  ON l.P_ID = p.P_ID
WHERE l.Lives_Earned = 2 and l.Stages_crossed >=3
GROUP BY  L1_code

----------------------------------------------------------------------------------------------



-- Q3) Find the total number of stages crossed at each diffuculty level
-- where for Level2 with players use zm_series devices. Arrange the result
-- in decsreasing order of total number of stages crossed.

-- show total stages for level 2 players use zm_series 
SELECT COUNT(l.Stages_crossed) AS Total_Stages,
       l.Difficulty
FROM [game].[dbo].[level] l
JOIN [game].[dbo].[player] p
 ON l.P_ID = p.P_ID
WHERE l.Level = 2 
      AND l.Dev_ID LIKE 'zm%'
GROUP BY  l.Difficulty
ORDER BY Total_Stages DESC 

----------------------------------------------------------------------------------------------



-- Q4) Extract P_ID and the total number of unique dates for those players 
-- who have played games on multiple days.


--- show numbers of times players play the game 

SELECT l.P_Id,
       COUNT(DISTINCT l.TimeStamp) AS NUM_Times
FROM [game].[dbo].[level] l
GROUP BY l.P_Id

----------------------------------------------------------------------------------------------



-- Q5) Find P_ID and level wise sum of kill_counts where kill_count
-- is greater than avg kill count for the Medium difficulty.

-- show sum of kills for each players 

SELECT P_ID,
       Level, SUM(Kill_Count) as Sum_Kill_Count
FROM [game].[dbo].[level] 
WHERE Difficulty = 'Medium' and 
	  Kill_Count > ( SELECT AVG(Kill_Count) 
                     FROM [game].[dbo].[level]
                     WHERE Difficulty = 'Medium'
                   )
GROUP BY  P_ID, Level

----------------------------------------------------------------------------------------------



-- Q6)  Find Level and its corresponding Level code wise sum of lives earned 
-- excluding level 0. Arrange in asecending order of level.


-- 

SELECT Level,
       p.L1_Code,
       p.L2_Code,
       SUM(l.Lives_Earned) AS SUM_Lives_Earned
FROM [game].[dbo].[level] l
JOIN [game].[dbo].[player] p
  ON l.P_ID = p.P_ID
WHERE l.Level != 0
GROUP BY Level,
		 p.L1_Code,
		 p.L2_Code
ORDER BY 1 ASC

----------------------------------------------------------------------------------------------



-- Q7) Find Top 3 score based on each dev_id and Rank them in increasing order
-- using Row_Number. Display difficulty as well. 

-- for each Device_ID find the largest 3 Scores recorded

WITH Scores AS (
    SELECT l.Dev_ID,
           l.score,
           l.difficulty,
           ROW_NUMBER() OVER(PARTITION BY l.Dev_ID ORDER BY l.score DESC) AS score_rank
    FROM [game].[dbo].[level] l
  )
SELECT Dev_ID,
       score,
       difficulty
FROM Scores
WHERE score_rank <= 3
ORDER BY score_rank;

----------------------------------------------------------------------------------------------



-- Q8) Find first_login datetime for each device id

-- for each Device_ID find the first login time

SELECT Dev_ID,
       MIN(TimeStamp) AS First_Login
FROM [game].[dbo].[level]
GROUP BY Dev_ID 

*/----------------------------------------------------------------------------------------------



-- Q9) Find Top 5 score based on each difficulty level and Rank them in 
-- increasing order using Rank. Display dev_id as well.

-- for each Device_ID find the largest 5 Scores recorded with the Difficulty level

WITH Diff_Score 
AS (
  SELECT l.Dev_ID,
         l.Score,
		 l.Difficulty,
         RANK() OVER(PARTITION BY Difficulty ORDER BY Score DESC) AS Top_Score
  FROM [game].[dbo].[level] l
  )
SELECT Dev_ID,
       Score,
       Difficulty
FROM Diff_Score 
WHERE Top_Score >=5
ORDER BY Top_Score;

----------------------------------------------------------------------------------------------



-- Q10) Find the device ID that is first logged in(based on start_datetime) 
-- for each player(p_id). Output should contain player id, device id and 
-- first login datetime.


-- for each Device_ID find the first login time for each player

SELECT P_ID,
       Dev_ID,
       MIN(TimeStamp) AS first_login_datetime
FROM [game].[dbo].[level]
GROUP BY P_ID, Dev_ID

----------------------------------------------------------------------------------------------



-- Q11) For each player and date, how many kill_count played so far by the player. That is, the total number of games played
-- by the player until that date.
-- a) window function
-- b) without window function

--------a)With Window Function 

--

SELECT L.P_ID,
       L.TimeStamp,
       SUM(L.Kill_Count) OVER(PARTITION BY L.P_ID ORDER BY TimeStamp) AS Kill_Count
FROM [game].[dbo].[level] L



-------b)Without Window Function



SELECT L.P_ID,
       L.TimeStamp,
       SUM(L.Kill_Count) AS Sum_Kill_Count
FROM [game].[dbo].[level] L
JOIN [game].[dbo].[level] L2
  ON L.P_ID = L2.P_ID 
     AND L.TimeStamp >= L2.TimeStamp
GROUP BY L.P_ID,
		 L.TimeStamp
ORDER BY L.P_ID,
		 L.TimeStamp

----------------------------------------------------------------------------------------------



-- Q12) Find the cumulative sum of stages crossed over a start_datetime 


SELECT L.TimeStamp,
       L.Stages_crossed,
       SUM(L.Stages_crossed) OVER (ORDER BY L.TimeStamp) AS cumulative_stages_crossed
FROM [game].[dbo].[level] L

----------------------------------------------------------------------------------------------



-- Q13) Find the cumulative sum of an stages crossed over a start_datetime 
-- for each player id but exclude the most recent start_datetime



WITH PreviousStartTimes AS (
    SELECT P_ID,
           MAX(L.TimeStamp) AS most_recent_start_time
    FROM [game].[dbo].[level] L
    GROUP BY P_ID
)
SELECT l.P_ID,
       l.TimeStamp,
       l.stages_crossed,
       SUM(l.stages_crossed) OVER (PARTITION BY l.P_ID ORDER BY l.TimeStamp) AS cumulative_stages_crossed
FROM [game].[dbo].[level] l
JOIN PreviousStartTimes p ON l.P_ID = p.P_ID
WHERE l.TimeStamp < p.most_recent_start_time;

----------------------------------------------------------------------------------------------



-- Q14) Extract top 3 highest sum of score for each device id and the corresponding player_id


WITH TopScores AS (
    SELECT P_ID, Dev_ID,
           SUM(score) AS total_score,
           ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY SUM(score) DESC) AS rank
    FROM [game].[dbo].[level]
    GROUP BY P_ID,
          Dev_ID
)
SELECT P_ID,
       Dev_ID,
       total_score
FROM TopScores
WHERE rank <= 3;

----------------------------------------------------------------------------------------------



-- Q15) Find players who scored more than 50% of the avg score scored by sum of 
-- scores for each player_id



SELECT P_ID
FROM (
    SELECT P_ID,
           SUM(score) AS total_score,
           AVG(SUM(score)) OVER () AS avg_total_score
    FROM [game].[dbo].[level]
    GROUP BY P_ID
) AS subquery
WHERE total_score > 0.5 * avg_total_score;

----------------------------------------------------------------------------------------------



-- Q16) Create a stored procedure to find top n Headshots_Count based on each dev_id and Rank them in increasing order
-- using Row_Number. Display difficulty as well.

--/*

WITH TopHeadshots AS (
    SELECT Dev_ID,
           difficulty,
           Headshots_Count,
           ROW_NUMBER() OVER(PARTITION BY Dev_ID ORDER BY Headshots_Count ASC) AS headshot_rank
    FROM [game].[dbo].[level]
)
SELECT Dev_ID,
       difficulty,
       Headshots_Count
FROM TopHeadshots
WHERE headshot_rank <= 5;

--*/----------------------------------------------------------------------------------------------

-- Q17) Create a function to return sum of Score for a given player_id.



CREATE TEMP FUNCTION GetPlayerScore(player_id INT64)
 AS (
  (SELECT SUM(score)
  FROM [game].[dbo].[level]
  WHERE P_ID = player_id)
);

SELECT GetPlayerScore(211) AS player_score;



CREATE FUNCTION GetPlayerScore (@player_id INT)
RETURNS INT
AS
BEGIN
    DECLARE @total_score INT;
    
    SELECT @total_score = SUM(Score)
    FROM [game].[dbo].[level]
    WHERE P_ID = @player_id;
    
    RETURN @total_score;
END;


SELECT [game].[dbo].GetPlayerScore(211) AS player_score;



---just to ensure that our function work well
SELECT SUM(Score)
    FROM [game].[dbo].[level]
    WHERE P_ID = 211;