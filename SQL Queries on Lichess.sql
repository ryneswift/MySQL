CREATE TABLE combined_usernames_2013 (
    Username VARCHAR(40) NOT NULL
);

CREATE TABLE combined_usernames_2014 (
    Username VARCHAR(40) NOT NULL
);



INSERT INTO combined_usernames_2013 (Username)
SELECT DISTINCT Black
FROM (
	#Gets the usernames of players who played as white and black in 2013
	WITH m2013_white_distinct AS(
		SELECT 
			DISTINCT White
		FROM 
			merged_2013_shortened
	)
	,
	m2013_black_distinct AS(
		SELECT 
			DISTINCT Black
		FROM 
			merged_2013_shortened
	)
	,
    #Performing an outer join to get all players who played
	comb_usernames_2013 AS(
		SELECT *
		FROM 
			m2013_white_distinct 
		LEFT JOIN 
			m2013_black_distinct
		ON 
			m2013_white_distinct.White = m2013_black_distinct.Black
            
		UNION
        
		SELECT * 
		FROM 
			m2013_black_distinct
		LEFT JOIN 
			m2013_white_distinct 
		ON 
			m2013_black_distinct.Black = m2013_white_distinct.White
	)
	#The combined_usernames query returns two columns, White and Black. We only want the players who have played games as both
	#colours, so we will only use the Black column, given that it contains the players who have played as both sides, and
    #White contains players only playing for one side
    
		SELECT 
			distinct Black
		FROM 
			comb_usernames_2013
		WHERE 
			Black IS NOT NULL
	)
    AS alias_combined_usernames_2013
;



#Making this query again since mySQL doesn't support functions that can accept tables as parameters, and since
#we want all the usernames of theplayers who have played as both colours in 2014

INSERT INTO combined_usernames_2014 (Username)
SELECT DISTINCT Black
FROM (
	#Gets the usernames of players who played as white and black in 2014
	WITH m2014_white_distinct AS(
		SELECT 
			DISTINCT White
		FROM 
			merged_2014_shortened
	)
	,
	m2014_black_distinct AS(
		SELECT 
			DISTINCT Black
		FROM 
			merged_2014_shortened
	)
	,
    #Performing an outer join to get all players who played
	comb_usernames_2014 AS(
		SELECT *
		FROM 
			m2014_white_distinct 
		LEFT JOIN 
			m2014_black_distinct
		ON 
			m2014_white_distinct.White = m2014_black_distinct.Black
            
		UNION
        
		SELECT * 
		FROM 
			m2014_black_distinct
		LEFT JOIN 
			m2014_white_distinct 
		ON 
			m2014_black_distinct.Black = m2014_white_distinct.White
	)
	#The combined_usernames query returns two columns, White and Black. We only want the players who have played games as both
	#colours, so we will only use the Black column, given that it contains the players who have played as both sides, and
    #White contains players only playing for one side
    
		SELECT 
			DISTINCT Black
		FROM 
			comb_usernames_2014
		WHERE 
			Black IS NOT NULL
	)
    AS alias_combined_usernames_2014
;



#This shows the players that didn't play in 2013 but played in 2014
SELECT 
	DISTINCT cu2014.Username
FROM 
	combined_usernames_2014 AS cu2014
LEFT JOIN 
	combined_usernames_2013 AS cu2013
ON 
	cu2013.Username = cu2014.Username
WHERE 
	cu2013.Username IS NULL
;



#Want to find the players who have played more than 100 games as both white and black

#Gets the players that have played more than 100 games as white
WITH white_more_than_100 AS(
	SELECT 
		White
	FROM 
		merged_2013_shortened
	GROUP BY 
		White
	HAVING 
		COUNT(White) >100
)
,
#Gets the players that have played more than 100 games as black
black_more_than_100 AS(
	SELECT 
		Black
	FROM 
		merged_2013_shortened
	GROUP BY 
		Black
	HAVING 
		COUNT(Black) >100
)
#Gets the players that have played more than 100 games as both white and black
#Both columns White and Black return as the same, so we can pick only one column without losing any information
SELECT 
	DISTINCT White AS Player
FROM 
	white_more_than_100 wmt100
JOIN 
	black_more_than_100 bmt100
ON 
	wmt100.White = bmt100.Black
;




#Ordering players by their win percentages where the number of games they've played as white is more than 50
WITH white_wins AS(
	SELECT 
		White, 
        SUM(CASE WHEN Result = 1 THEN 1 ELSE 0 END) AS num_wins_white
    FROM 
		merged_2013_shortened
    GROUP BY
		White
)
,
total_white_games AS(
	SELECT 
		White, 
        COUNT(White) AS num_games_white
    FROM 
		merged_2013_shortened
    GROUP BY  
		White
)
SELECT 
	ww.White, 
    CAST(ww.num_wins_white AS DECIMAL(10, 2)) / twg.num_games_white AS win_percentage,
	twg.num_games_white, 
    ww.num_wins_white
FROM 
	white_wins ww
JOIN 
	total_white_games twg
ON 
	twg.White = ww.White
WHERE 
	twg.num_games_white > 49
ORDER BY
	win_percentage DESC
;



#Comparing average sum_eval values for wins and losses of white players
WITH white AS(
	SELECT 
		White, 
        SUM(CASE WHEN Result = 1 THEN sum_eval ELSE 0 END) AS sum_sum_eval_white_wins,
		SUM(CASE WHEN Result = 1 THEN 1 ELSE 0 END) AS num_white_wins,
		SUM(CASE WHEN Result = -1 THEN sum_eval ELSE 0 END) AS sum_sum_eval_white_losses,
		SUM(CASE WHEN Result = -1 THEN 1 ELSE 0 END) AS num_white_losses
    FROM 
		merged_2013_shortened
    GROUP BY
		White
)
,
avg_sum_eval AS(
	SELECT 
		White, 
        CAST(sum_sum_eval_white_wins AS DECIMAL(10, 2))/num_white_wins AS average_sum_eval_for_wins,
		CAST(sum_sum_eval_white_losses AS DECIMAL(10, 2))/num_white_losses AS average_sum_eval_for_losses
    FROM 
		white
)
SELECT *
FROM 
	avg_sum_eval
WHERE 
	(average_sum_eval_for_wins IS NOT NULL) AND 
    (average_sum_eval_for_losses IS NOT NULL)
ORDER BY 
	White DESC
#Comparing the average sum_eval value for each player, depending on whether they won or lost
;



#Display win percentages by ECO codes for the 20 most popular openings for white in the dataset
WITH white_ECO_win_percentages AS(
	SELECT ECO, 
		sum(CASE WHEN Result = 1 THEN 1 ELSE 0 END) num_white_wins,
		count(White) AS num_white_games,
		AVG(total_half_moves) AS average_moves_per_game
    FROM 
		merged_2013_shortened
    GROUP BY 
		ECO
)
SELECT 
	ECO, 
    CAST(num_white_wins AS DECIMAL(10, 2))/num_white_games AS win_proportion,
	ROUND(average_moves_per_game,2) AS average_moves_per_game
FROM 
	white_ECO_win_percentages
WHERE 
	num_white_games>100
ORDER BY 
	num_white_games DESC
LIMIT 20
;




#Gets the highest rating achieved by each white player in 2013
WITH highest_white_ratings AS(
	SELECT 
		White, 
        MAX(White_Elo) AS max_white
	FROM 
		merged_2013_shortened
	GROUP BY 
		White
),
#Gets the highest rating achieved by each black player in 2013
highest_black_ratings AS(
	SELECT 
		Black, 
        MAX(Black_Elo) AS max_black
    FROM 
		merged_2013_shortened
	GROUP BY 
		Black
),
highest_ratings AS(
#Took the average of the players' highest white and black ratings. Did this instead of looking at the ratings for one colour
#because some had ratings which were significantly higher for one colour than the other

	SELECT 
		hwr.White AS Player, 
		(AVG(hwr.max_white) + AVG(hbr.max_black)) / 2 AS Avg_Highest_Rating, max_white, max_black 
	FROM 
		highest_white_ratings hwr

	#join the names together so that only players who have played as both colours are included
	JOIN 
		highest_black_ratings hbr
	ON 
		hbr.Black = hwr.White
    GROUP BY 
		hwr.White
)
,
#Gets the 20 highest rated players for 2013
highest_rated_2013 AS (
	SELECT 
		hr.Player, 
		ROUND(hr.Avg_Highest_Rating, 2) AS average_rating, 
        hr.max_white, 
        hr.max_black
	FROM 
		highest_ratings hr
	ORDER BY 
		hr.Avg_Highest_Rating DESC
	LIMIT 20
)
#Comparing the highest rating achieved as white and black for the 20 highest rated players in 2013 who played in 2014.
#If the player was in the top 20 in 2013 but didn't play in 2014, they are excluded from the result.
SELECT 
	m2014s.White, 
    MAX(m2014s.White_Elo) AS highest_white_rating_2014, 
    MAX(m2014s.Black_Elo) AS highest_black_rating_2014,
	hr2013.max_white AS highest_white_elo_2013, 
    hr2013.max_black AS highest_black_elo_2013

FROM 
	merged_2014_shortened m2014s
JOIN 
	highest_rated_2013 hr2013
ON 
	hr2013.Player = m2014s.White
GROUP BY
	White
;



#Analyze whether the average total_moves for games increased or decreased between 2013 and 2014, 
#and determine if this trend is consistent across the 20 most popular time controls.

WITH popular_time_controls AS(
	SELECT 
		TimeControl, 
        COUNT(White) AS total_num_games   #total_num_games is the total number of games per time control
    from 
		merged_2013_shortened
    GROUP BY 
		TimeControl
),

#Getting the average number of moves per time control throughout 2013
time_control_data_2013 AS(
	SELECT 
		SUM(m2013s.total_half_moves)/ptc.total_num_games AS avg_total_half_moves, 
		m2013s.TimeControl, 
		ptc.total_num_games
	FROM 
		merged_2013_shortened m2013s
	JOIN 
		popular_time_controls ptc
	ON 
		ptc.TimeControl = m2013s.TimeControl
	GROUP BY 
		m2013s.TimeControl
	ORDER BY 
		ptc.total_num_games DESC
	LIMIT 20
)
#Getting the average number of moves per time control throughout 2014
SELECT 
	tcd2013.avg_total_half_moves AS avg_moves_2013, 
    tcd2013.total_num_games AS total_games_2013,
    SUM(m2014s.total_half_moves)/COUNT(*) AS avg_moves_2014, 
    COUNT(*) AS total_games_2014,  
    m2014s.TimeControl
FROM
	merged_2014_shortened m2014s
JOIN
	time_control_data_2013 tcd2013
ON
	tcd2013.TimeControl = m2014s.TimeControl
GROUP BY 
	m2014s.TimeControl
ORDER BY
	tcd2013.total_num_games DESC
;


#Find players who won more games as Black than as White in 2013, despite having a lower average Elo as Black, where the player 
#played at least 20 games as both white and black, and has their average black elo as being at least 50 points lower than 
#their average white rating.

#Finding the average elo of each player in their games they played as white.
#Have to use separate CTEs to correctly get the average elo for each colour.
WITH average_elo_white AS(
	SELECT 
		White,
        AVG(White_Elo) AS avg_w_elo, 
        COUNT(White) AS num_games_w,
        SUM(CASE WHEN Result = 1 THEN 1 ELSE 0 END) AS num_wins_w
    FROM 
		merged_2013_shortened
    GROUP BY 
		White
)
,
average_elo_black AS(
	SELECT 
		Black, 
        AVG(Black_Elo) AS avg_b_elo, 
        COUNT(Black) AS num_games_b,
        SUM(CASE WHEN Result = -1 THEN 1 ELSE 0 END) AS num_wins_b
    FROM 
		merged_2013_shortened
    GROUP BY 
		Black
)
,
#Can exclude the Black column because the White and Black column will return as the same because of the join statement
compare_elos AS(
	SELECT 
		White AS Username, 
        avg_w_elo, 
        avg_b_elo, 
        num_wins_b-num_wins_w AS diff_in_black_and_white_wins
    FROM 
		average_elo_white aew
	JOIN 
		average_elo_black aeb
	ON 
		aew.White = aeb.Black
	WHERE 
		(aew.num_games_w>=20) AND (aeb.num_games_b>=20)
)
#Gets the names of the players who were lower rated as black and has their average black elo as being 
#at least 50 points lower than their average white rating, and the number of black wins exceeds the number of white wins.
SELECT * 
FROM 
	compare_elos
WHERE 
	((avg_w_elo - avg_b_elo)>=50) AND (diff_in_black_and_white_wins >=1)
ORDER BY
	diff_in_black_and_white_wins DESC
;


#When sum_eval is significant (-50 or +50) determine how often the favoured side wins in the 60+0 
#and 300+0 time controls, which are two of the most popular in the dataset.

#We want to examine the relationship between time and game outcome because when there is less time in a game, 
#sum_eval is thought to become less significant in predicting game outcomes

#Segregate the results by Elo, with two categories, lower and higher elo
#lower is when both players are rated 1000 or below, higher is when both are 1900 or above


#This CTE appends another column to the existing merged_2013_shortened table
WITH m2013s_elo_categories AS(
	SELECT 
		Result, 
        sum_eval, 
        TimeControl, 
    CASE WHEN 
			((White_Elo <=1300) AND (Black_Elo <= 1300))  THEN 1
		WHEN 
			((White_Elo >=1900) AND (Black_Elo >= 1900)) THEN 0
		ELSE 2
        END AS 
			game_elo_category
        
	FROM 
		merged_2013_shortened m2013s
),
#This CTE does everything but get the win rates for each elo category and time control.
main_CTE AS(
SELECT 
	TimeControl,
    CASE 
		WHEN game_elo_category=0 THEN ">=1900"
        ELSE "<=1300"
	END AS
		elo_category,
	SUM(CASE WHEN 
			((Result = -1) AND (sum_eval <= -50))  THEN 1
		WHEN 
			((Result = 1) AND (sum_eval >= 50)) THEN 1 
		ELSE 0
        END) 
			AS num_wins_favoured_side,
        
    SUM(CASE 
		WHEN (sum_eval <= -50) THEN 1
		When (sum_eval >= 50) THEN 1 
		ELSE 0
        END) 
			AS num_games_favoured_side

FROM 
	m2013s_elo_categories AS m2013ec
WHERE 
	((TimeControl ='60+0') OR (TimeControl ='300+0')) AND
    ((game_elo_category=1) OR (game_elo_category = 0))
GROUP BY
	game_elo_category, TimeControl
ORDER BY
	TimeControl
)
SELECT 
	*, 
    num_wins_favoured_side/num_games_favoured_side AS win_rate
FROM
	main_CTE
;




#For each year, determine if there is an decreasing trend in the difference between players' Elos in games.
#Investigating this because as the years went by, Lichess became more popular, which should lead to 
#a greater proportion of evenly matched games


#Combining both years together into one dataset/table
WITH both_years AS(
	SELECT
		m2013s.White, 
        m2013s.Elo_Difference, 
        '2013' AS yr
	FROM 
		merged_2013_shortened m2013s
	LEFT JOIN
		merged_2014_shortened m2014s
	ON
		m2013s.White = m2014s.White
	UNION
	
	SELECT 
		m2014s.White, m2014s.Elo_Difference, '2014' AS yr
	FROM
		merged_2013_shortened m2013s
	RIGHT JOIN
		merged_2014_shortened m2014s
	ON
		m2013s.White = m2014s.White
)
,
both_years_elo_categories AS(
	SELECT 
		*, 
    CASE WHEN 
			(ABS(Elo_Difference)<=50)  THEN 0
		WHEN 
			(ABS(Elo_Difference) > 50 AND ABS(Elo_Difference) <= 100) THEN 1
		WHEN
			(ABS(Elo_Difference) > 100 AND ABS(Elo_Difference) <= 200) THEN 2
		else 3
        END AS 
			elo_diff_category
	FROM 
		both_years 
)
SELECT 
	yr AS year, 
    elo_diff_category, 
    COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY yr) AS proportion_of_games
FROM 
	both_years_elo_categories
GROUP BY
	yr, elo_diff_category
ORDER BY 
	yr, elo_diff_category
;


#Relationship Between Time Control and Opening Choice:

#Investigate whether certain openings are more prevalent or successful under specific time controls. 
#Determine if players adjust their opening strategies based on the speed of the game.

#Examine white players and the win rates for them only
#Limit the results to 60+0 and 300+0


WITH win_rate_by_opening_and_time_control AS(
	SELECT
		TimeControl, 
        COUNT(ECO) AS num_games, 
        ECO,
        SUM(CASE 
			WHEN Result=1 THEN 1
			ELSE 0
            END) AS num_wins_white,            
			ROW_NUMBER() OVER (PARTITION BY TimeControl ORDER BY COUNT(ECO) DESC) AS opening_rank
	FROM
		merged_2013_shortened
	WHERE
		(TimeControl = '60+0') OR (TimeControl = '300+0')		
	GROUP BY
		TimeControl, ECO 
)
SELECT 
	*, 
    num_wins_white/num_games AS win_rate
FROM 
	win_rate_by_opening_and_time_control
WHERE 
	opening_rank <= 10
ORDER BY 
	ECO
;




