
 
use cricket;
select * from ball_by_ball;
select * from batsman_scored;
select * from extra_runs;
select * from match_;
select * from player;
select * from player_match;
select * from team;
select * from wicket_taken;


 /* 1. List the names of all left-handed batsmen from England. Order the results alphabetically. */
 
 select * from player
 where batting_hand = 'Left-hand bat' and country_name ='england'
 order by player_name asc;
 
 /*2. List the names and age (in years, should be an integer) as on 2018-12-02 (12th Feb 2018) 
      of all bowlers with skill “Legbreak googly” who are 28 or more in age.
      Order the result in decreasing order of their ages. Resolve ties alphabetically. */
 
  select *,str_to_date(dob,'%d-%m-%Y') ,('2018'-extract(year from  str_to_date(dob,'%d-%m-%Y'))) as age from player 
 where bowling_skill = 'Legbreak googly' and ('2018'-extract(year from  str_to_date(dob,'%d-%m-%Y'))) >=28
 order by age desc ,player_name;
 
 
 /*3. List the match ids and toss winning team IDs where the toss winner of a match decided to bat first. 
	  Order results in increasing order of match ids. */
      
      select match_id,toss_winner/*,toss_decision*/ from match_
      where toss_decision = 'bat'
      order by match_id ;
      
/* 4. In the match with match id 335987, list the over ids and runs scored where at most 7 runs were scored.
 Order the over ids in decreasing order of runs scored.
 Resolve ties by listing the over ids in increasing order. */
 
	select over_id,sum(runs_scored) as runs_scored/*,match_id,innings_no*/ from 
    (select match_id,over_id,ball_id,runs_scored ,innings_no from batsman_scored as bs
    union (select match_id,over_id,ball_id,extra_runs as runs_scored ,innings_no from extra_runs)) as r
    where match_id = 335987
    group by innings_no,over_id
    having sum(runs_scored) <=7
    order by runs_scored desc,over_id ;
    
  
   
/*5. List the names of those batsmen who were bowled at least once in alphabetical order of their names. */

select distinct player_out , player_name from wicket_taken as wt
left join player as p on p.player_id = wt.player_out
where kind_out = 'bowled'
order by player_name;



/* 6. Find the bowler who has the best average overall. Bowling average is calculated using the following formula: 
bowling average = Number of runs given/ Number of wickets taken 
Calculate the average up to 3 decimal places and return the bowler with the lowest average runs per wicket. In case of a tie, return the results in alphabetical order. 
*/

select * from ball_by_ball ;
select * from batsman_scored;
select * from player;
select * from extra_runs;
select * from wicket_taken;

select player_name/*,player_id,total_runs_given,no_of_wickets_taken,round(bowling_avg,3) as bowling_avg*/ from player as k right join
( select bowler,sum(runs_given) as total_runs_given,sum(wickets_taken) as no_of_wickets_taken ,(sum(runs_given)/sum(wickets_taken)) as bowling_avg from 
	(select concat(innings_no,' ',match_id,' ',over_id) as c3,count(player_out) as wickets_taken from wicket_taken
	group by c3 ) as q inner join 
	( select c2,bowler , /*sum(runs_given) as */ runs_given  from 
		( select distinct c2,c1,bowler,innings_no,match_id,over_id,run_scored as runs_given from 
			(select concat(innings_no,' ',match_id,' ',over_id)as c2 ,bowler from ball_by_ball )as bb right join 
				( select innings_no,match_id,over_id,sum(runs_scored) as run_scored , concat(r.innings_no,' ',r.match_id,' ',r.over_id) as c1 from 
					(	select match_id,over_id,ball_id,runs_scored ,innings_no from batsman_scored as bs
						union (select match_id,over_id,ball_id,extra_runs as runs_scored ,innings_no from extra_runs)
					) as r 
				group by innings_no,match_id,over_id
				) as t1 on t1.c1 = bb.c2
		) as t2 
	)as f on f.c2= q.c3
	group by bowler
 ) as l on l.bowler =k.player_id
 order by bowling_avg ,player_name limit 1 ;
 
 

 

 
 /*7. List the players and the corresponding teams where the player played as “CaptainKeeper” and won the match. 
      Order results alphabetically on the player’s name. */
 
 select /*match_id,q.team_id,q.player_id,*/ distinct q.player_name,q.name from match_ as m right join 
 (
 select distinct pm.player_id,player_name,pm.team_id,name from player_match as pm left join player as p on p.player_id = pm.player_id 
 left join team as t on t.team_id = pm.team_id
 where role = 'captainkeeper'
 )as q on q.team_id = m.match_winner
 order by q.player_name asc;
 


/* 8. List the names of all players and their runs scored (who have scored at least 50 runs in any match). Order results in decreasing order of runs scored.
    Resolve ties alphabetically. */

select q.match_id,q.batsman,q.runs_scored,p.player_name from 
(select bs.match_id,batsman,sum(runs_scored) as runs_scored from 
(select concat(match_id,' ',innings_no,' ',over_id,' ',ball_id) as a ,runs_scored ,match_id from batsman_scored) as bs left join 
(select concat(match_id,' ',innings_no,' ',over_id,' ',ball_id) as b, striker as batsman from ball_by_ball) as bb on bb.b = bs.a
group by match_id,batsman
having sum(runs_scored)>=50) as q left join player as p on q.batsman=p.player_id
order by runs_scored desc,player_name;



/*9. List the player names who scored a century but their teams lost the match. Order results alphabetically. */

select o.player_name/*,o.match_id,o.batsman as player_id,o.runs_scored,o.team_id */ from 
(select distinct w.match_id,w.batsman,w.runs_scored,w.player_name,pm.team_id from 
(
select q.match_id,q.batsman,q.runs_scored,p.player_name from 
(select bs.match_id,batsman,sum(runs_scored) as runs_scored from 
(select concat(match_id,' ',innings_no,' ',over_id,' ',ball_id) as a ,runs_scored ,match_id from batsman_scored) as bs left join 
(select concat(match_id,' ',innings_no,' ',over_id,' ',ball_id) as b, striker as batsman from ball_by_ball) as bb on bb.b = bs.a
group by match_id,batsman
having sum(runs_scored)>=100) as q left join player as p on q.batsman=p.player_id
) as w left join player_match as pm on pm.player_id = w.batsman and pm.match_id = w.match_id)as o inner join 
(
select * , case when match_winner = team_1 then team_2 
                else team_1
                end match_looser
 from match_
) as y on y.match_id =o.match_id and y.match_looser =o.team_id
order by player_name;



/* 10. List match ids and venues where KKR has lost the game. Order results in increasing order of match id.  */

select match_id,venue from team as t right join 
(select * , case when match_winner = team_1 then team_2 
                else team_1
                end match_looser
 from match_) as m on m.match_looser = t.team_id 
 where name = 'Kolkata Knight Riders';
 

 
 /*11. List the names of top 10 players who have the best batting average in season 5. 
 Batting average can be calculated according to the following formula: 
batting average(player) = Number of runs scored by player/ Number of matches player has batted in 
The output should contain exactly 10 rows. Report results up to 3 decimal places. Resolve ties alphabetically.*/



select player_name ,runs_scored , no_of_match_played ,round((runs_scored / no_of_match_played ),3) as batting_average from player as p right join 
(
	select batsman , sum(runs_scored) as runs_scored ,count(batsman) as no_of_match_played  from 
		(
			select season_id,match_id,batsman,sum(runs_scored) as runs_scored  ,concat(match_id,' ',batsman) from 
					( select season_id,o.match_id,runs_scored,o.batsman,a from match_ as m inner join 
						(select * from 
							(select concat(match_id,' ',innings_no,' ',over_id,' ',ball_id) as a ,runs_scored ,match_id from batsman_scored) as bs left join 
							(select concat(match_id,' ',innings_no,' ',over_id,' ',ball_id) as b, striker as batsman from ball_by_ball) as bb on bb.b = bs.a
						)as o on o.match_id = m.match_id where m.season_id = 5 ) as i
			group by match_id,batsman
            /*having season_id = 5*/
		) as k 
	group by batsman 
) as w on w.batsman = p.player_id 
order by batting_average desc limit 10;






##############################################################             OR              #####################################################################################################################


select striker,player_name,runs_scored,no_of_match_played,(runs_scored/no_of_match_played) as batting_average from player as pl right join
	(
	select striker,sum(runs_scored) as runs_scored , count(striker) as no_of_match_played from 
		(
		select p.match_id,striker,sum(runs_scored) as runs_scored from 
			(
				select * from 
				(select concat(match_id , ' ' ,innings_no , ' ' , over_id ,' ',ball_id) as a , striker  from ball_by_ball) as bb inner join 
				(select  match_id ,concat(match_id ,' ' ,innings_no ,' ', over_id ,' ',ball_id) as b,runs_scored from batsman_scored ) as bs on bs.b = bb.a
			) as p inner join 
					(select match_id ,season_id  from match_
					where season_id = 5) as m on m.match_id = p.match_id 
			group by match_id , striker
		) as w 
	group by striker
	) as f on f.striker = pl.player_id
order by batting_average desc
limit 10 ;
