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
	with m2013_white_distinct as(
		select distinct White
		from merged_2013_shortened
	)
	,
	m2013_black_distinct as(
		select distinct Black
		from merged_2013_shortened
	)
	,
    #Performing an outer join to get all players who played
	comb_usernames_2013 as(
		select *
		from m2013_white_distinct 
		left join m2013_black_distinct
		on m2013_white_distinct.White = m2013_black_distinct.Black
		UNION
		select * 
		from m2013_black_distinct
		left join m2013_white_distinct 
		on m2013_black_distinct.Black = m2013_white_distinct.White
	)
	#The combined_usernames query returns two columns, White and Black. We only want the players who have played games as both
	#colours, so we will only use the Black column, given that it contains the players who have played as both sides, and
    #White contains players only playing for one side
		select distinct Black
		from comb_usernames_2013
		where Black is not null
	)
    AS alias_combined_usernames_2013
;



#Making this query again since mySQL doesn't support functions that can accept tables as parameters, and since
#we want all the usernames of theplayers who have played as both colours in 2014

INSERT INTO combined_usernames_2014 (Username)
SELECT DISTINCT Black
FROM (
	#Gets the usernames of players who played as white and black in 2014
	with m2014_white_distinct as(
		select distinct White
		from merged_2014_shortened
	)
	,
	m2014_black_distinct as(
		select distinct Black
		from merged_2014_shortened
	)
	,
    #Performing an outer join to get all players who played
	comb_usernames_2014 as(
		select *
		from m2014_white_distinct 
		left join m2014_black_distinct
		on m2014_white_distinct.White = m2014_black_distinct.Black
		UNION
		select * 
		from m2014_black_distinct
		left join m2014_white_distinct 
		on m2014_black_distinct.Black = m2014_white_distinct.White
	)
	#The combined_usernames query returns two columns, White and Black. We only want the players who have played games as both
	#colours, so we will only use the Black column, given that it contains the players who have played as both sides, and
    #White contains players only playing for one side
		select distinct Black
		from comb_usernames_2014
		where Black is not null
	)
    AS alias_combined_usernames_2014
;



#This shows the players that didn't play in 2013 but played in 2014
select distinct cu2014.Username
from combined_usernames_2014 as cu2014
left join combined_usernames_2013 as cu2013
on cu2013.Username = cu2014.Username
where cu2013.Username is null
;



#Want to find the players who have played more than 100 games as both white and black

#Gets the players that have played more than 100 games as white
with white_more_than_100 as(
select White
from merged_2013_shortened
group by White
having count(White) >100
)
,
#Gets the players that have played more than 100 games as black
black_more_than_100 as(
select Black
from merged_2013_shortened
group by Black
having count(Black) >100
)
#Gets the players that have played more than 100 games as both white and black
#Both columns White and Black return as the same, so we can pick only one column without losing any information
select distinct White as Player
from white_more_than_100 wmt100
join black_more_than_100 bmt100
on wmt100.White = bmt100.Black
;




#Ordering players by their win percentages where the number of games they've played as white is more than 50
with white_wins as(
	select White, sum(CASE WHEN Result = 1 THEN 1 ELSE 0 END) as num_wins_white
    from merged_2013_shortened
    group by White
    #Having num_wins_white>50
)
,
total_white_games as(
	select White, count(White) as num_games_white
    from merged_2013_shortened
    group by White
)
select ww.White, CAST(ww.num_wins_white AS DECIMAL(10, 2)) / twg.num_games_white as win_percentage,
twg.num_games_white, ww.num_wins_white
from white_wins ww
join total_white_games twg
on twg.White = ww.White
where twg.num_games_white > 49
order by win_percentage DESC
;



#Comparing average sum_eval values for wins and losses of white players
with white as(
	select White, sum(CASE WHEN Result = 1 then sum_eval else 0 end) as sum_sum_eval_white_wins,
    sum(CASE WHEN Result = 1 then 1 else 0 end) num_white_wins,
    sum(CASE WHEN Result = -1 then sum_eval else 0 end) as sum_sum_eval_white_losses,
    sum(CASE WHEN Result = -1 then 1 else 0 end) num_white_losses
    from merged_2013_shortened
    group by White
)
,
avg_sum_eval as(
	select White, CAST(sum_sum_eval_white_wins AS DECIMAL(10, 2))/num_white_wins as average_sum_eval_for_wins,
    CAST(sum_sum_eval_white_losses AS DECIMAL(10, 2))/num_white_losses as average_sum_eval_for_losses
    from white
)
select *
from avg_sum_eval
where (average_sum_eval_for_wins is not null) and (average_sum_eval_for_losses is not null)
order by White DESC
#Comparing the average sum_eval value for each player, depending on whether they won or lost
;



#Display win percentages by ECO codes for the 20 most popular openings for white in the dataset
with white_ECO_win_percentages as(
	select ECO, sum(CASE WHEN Result = 1 then 1 else 0 end) num_white_wins,
    count(White) as num_white_games,
    avg(total_half_moves) as average_moves_per_game
    from merged_2013_shortened
    group by ECO
)
select ECO, CAST(num_white_wins AS DECIMAL(10, 2))/num_white_games as win_proportion,
round(average_moves_per_game,2) as average_moves_per_game
from white_ECO_win_percentages
where num_white_games>100
order by num_white_games DESC
LIMIT 20
;






#Gets the highest rating achieved by each white player in 2013
with highest_white_ratings as(
	select White, max(White_Elo) as max_white
	from merged_2013_shortened
	group by White
),
#Gets the highest rating achieved by each black player in 2013
highest_black_ratings as(
	select Black, max(Black_Elo) as max_black
    from merged_2013_shortened
	group by Black
),
highest_ratings as(
#Took the average of the players' highest white and black ratings. Did this instead of looking at the ratings for one colour
#because some had ratings which were significantly higher for one colour than the other

	select hwr.White as Player, (AVG(hwr.max_white) + AVG(hbr.max_black)) / 2 AS Avg_Highest_Rating, max_white, max_black 
	from highest_white_ratings hwr

	#join the names together so that only players who have played as both colours are included
	join highest_black_ratings hbr
	on hbr.Black = hwr.White
    group by hwr.White
)
,
#Gets the 20 highest rated players for 2013
highest_rated_2013 as (
	
	select hr.Player, round(hr.Avg_Highest_Rating, 2) as average_rating, hr.max_white, hr.max_black
	from highest_ratings hr
	order by hr.Avg_Highest_Rating desc
	LIMIT 20
)
#Comparing the highest rating achieved as white and black for the 20 highest rated players in 2013 who played in 2014.
#If the player was in the top 20 in 2013 but didn't play in 2014, they are excluded from the result.
select 
	m2014s.White, max(m2014s.White_Elo) as highest_white_rating_2014, 
    max(m2014s.Black_Elo) as highest_black_rating_2014,
	hr2013.max_white as highest_white_elo_2013, 
    hr2013.max_black as highest_black_elo_2013

from 
	merged_2014_shortened m2014s
join 
	highest_rated_2013 hr2013
on 
	hr2013.Player = m2014s.White
group by White
;



#Analyze whether the average total_moves for games increased or decreased between 2013 and 2014, 
#and determine if this trend is consistent across the 20 most popular time controls.

with popular_time_controls as (
	select TimeControl, count(White) as total_num_games   #total_num_games is the total number of games per time control
    from merged_2013_shortened
    group by TimeControl
),


#Getting the average number of moves per time control throughout 2013
time_control_data_2013 as(
select sum(m2013s.total_half_moves)/ptc.total_num_games as avg_total_half_moves, 
	m2013s.TimeControl, 
	ptc.total_num_games

from 
	merged_2013_shortened m2013s
join 
	popular_time_controls ptc

on 
	ptc.TimeControl = m2013s.TimeControl
group by 
	m2013s.TimeControl
order by 
	ptc.total_num_games desc
LIMIT 20
)
#Getting the average number of moves per time control throughout 2014
select 
	tcd2013.avg_total_half_moves as avg_moves_2013, tcd2013.total_num_games as total_games_2013,
    sum(m2014s.total_half_moves)/count(*) as avg_moves_2014, count(*) as total_games_2014,  m2014s.TimeControl

from
	merged_2014_shortened m2014s
join
	time_control_data_2013 tcd2013
on
	tcd2013.TimeControl = m2014s.TimeControl
group by 
	m2014s.TimeControl
order by
	tcd2013.total_num_games DESC
;




#Find players who won more games as Black than as White in 2013, despite having a lower average Elo as Black, where the player 
#played at least 20 games as both white and black, and has their average black elo as being at least 50 points lower than 
#their average white rating.

#Finding the average elo of each player in their games they played as white.
#Have to use separate CTEs to correctly get the average elo for each colour.
with average_elo_white as(
	select 
		White, avg(White_Elo) as avg_w_elo, count(White) as num_games_w,
        sum(CASE WHEN Result = 1 then 1 else 0 end) as num_wins_w
    from 
		merged_2013_shortened
    group by 
		White
)
,
average_elo_black as(
	select 
		Black, avg(Black_Elo) as avg_b_elo, count(Black) as num_games_b,
        sum(CASE WHEN Result = -1 then 1 else 0 end) as num_wins_b
    from 
		merged_2013_shortened
    group by 
		Black
)
,
#Can exclude the Black column because the White and Black column will return as the same because of the join statement
compare_elos as (
	select 
		White as Username, avg_w_elo, avg_b_elo, num_wins_b-num_wins_w as diff_in_black_and_white_wins
    from 
		average_elo_white aew
	join 
		average_elo_black aeb
	on 
		aew.White = aeb.Black
	Where 
		(aew.num_games_w>=20) and (aeb.num_games_b>=20)
)
#Gets the names of the players who were lower rated as black and has their average black elo as being 
#at least 50 points lower than their average white rating, and the number of black wins exceeds the number of white wins.
select 
	* 
from 
	compare_elos
where 
	((avg_w_elo - avg_b_elo)>=50) and (diff_in_black_and_white_wins >=1)
order by
	diff_in_black_and_white_wins DESC
;


#When sum_eval is significant (-50 or +50) determine how often the favoured side wins in the 60+0 
#and 300+0 time controls, which are two of the most popular in the dataset.

#We want to examine the relationship between time and game outcome because when there is less time in a game, 
#sum_eval is thought to become less significant in predicting game outcomes


#Segregate the results by Elo, do two categories, lower and higher elo
#lower is when both players are rated 1000 or below, higher is when both are 1900 or above


#This CTE appends another column to the existing merged_2013_shortened table
with m2013s_elo_categories as(
	select 
		Result, sum_eval, TimeControl, 
    CASE WHEN 
			((White_Elo <=1300) and (Black_Elo <= 1300))  then 1
		WHEN 
			((White_Elo >=1900) and (Black_Elo >= 1900)) then 0
		else 2
        end as game_elo_category
        
	from 
		merged_2013_shortened m2013s
),
#This CTE does everything but get the win rates for each elo category and time control.
main_CTE as(
select 
	TimeControl,
    case 
		when game_elo_category=0 then ">=1900"
        else "<=1300"
	end as
		elo_category,
	sum(CASE WHEN 
			((Result = -1) and (sum_eval <= -50))  then 1
		WHEN 
			((Result = 1) and (sum_eval >= 50)) then 1 
		else 0
        end) as num_wins_favoured_side,
        
    sum(CASE 
		WHEN 	(sum_eval <= -50) then 1
		When	(sum_eval >= 50)  then 1 
		else 0
        end) 
			as num_games_favoured_side
	#,
    #num_wins_favoured_side/num_games_large_sum_eval
from 
	m2013s_elo_categories as m2013ec
Where 
	((TimeControl ='60+0') or (TimeControl ='300+0')) and
    ((game_elo_category=1) or (game_elo_category = 0))
group by
	game_elo_category, TimeControl
order by
	TimeControl
)
select 
	*, num_wins_favoured_side/num_games_favoured_side as win_rate
from
	main_CTE
;




#For each year, determine if there is an decreasing trend in the difference between players' Elos in games.
#Investigating this because as the years went by, Lichess became more popular, which should lead to 
#a greater proportion of evenly matched games


#Combining both years together into one dataset/table
with both_years as(
	select
		m2013s.White, m2013s.Elo_Difference, '2013' as yr
	from 
		merged_2013_shortened m2013s
	left join
		merged_2014_shortened m2014s
	on
		m2013s.White = m2014s.White
	union
	
	select 
		m2014s.White, m2014s.Elo_Difference, '2014' as yr
	from
		merged_2013_shortened m2013s
	right join
		merged_2014_shortened m2014s
	on
		m2013s.White = m2014s.White
)
,
both_years_elo_categories as(
	select 
		*, 
    CASE WHEN 
			(abs(Elo_Difference)<=50)  then 0
		WHEN 
			(abs(Elo_Difference) > 50 AND abs(Elo_Difference) <= 100) then 1
		WHEN
			(abs(Elo_Difference) > 100 AND abs(Elo_Difference) <= 200) then 2
		else 
			3
        end as 
			elo_diff_category
	from 
		both_years 
)
select 
	yr as year, elo_diff_category, count(*)  / sum(count(*)) OVER (PARTITION BY yr) AS proportion_of_games
from 
	both_years_elo_categories
group by
	yr, elo_diff_category
order by 
	yr, elo_diff_category
;


#Relationship Between Time Control and Opening Choice:

#Investigate whether certain openings are more prevalent or successful under specific time controls. 
#Determine if players adjust their opening strategies based on the speed of the game.

#Examine white players and the win rates for them only
#Limit the results to 60+0 and 300+0


with win_rate_by_opening_and_time_control as(
	select
		TimeControl, count(ECO) as num_games, ECO,
        sum(CASE WHEN 
			Result=1  then 1
			else 0
            end) as num_wins_white,
            
        ROW_NUMBER() OVER (PARTITION BY TimeControl ORDER BY COUNT(ECO) DESC) AS opening_rank
	from
		merged_2013_shortened
	where 
		(TimeControl = '60+0') or (TimeControl = '300+0')		
	group by
		TimeControl, ECO 
)
select *, num_wins_white/num_games as win_rate
from win_rate_by_opening_and_time_control
WHERE opening_rank <= 10
order by ECO
;




