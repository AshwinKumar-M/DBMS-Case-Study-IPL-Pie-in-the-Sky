-- 1.	Show the percentage of wins of each bidder in the order of highest to lowest percentage.

select *,won_match/total_match*100 as percentage_won from(
select BIDDER_ID,
count(
case when BID_STATUS != 'Cancelled' then BID_STATUS end ) as total_match,
count(
case when BID_STATUS = 'won' then BID_STATUS end ) as won_match
from ipl_bidding_details
group by 1) t order by won_match/total_match*100 desc;

-- 2.	Display the number of matches conducted at each stadium with the stadium name and city.

select ims.STADIUM_ID,STADIUM_NAME,CITY,count(MATCH_ID)
from ipl_match_schedule ims join ipl_stadium si
on ims.STADIUM_ID=si.STADIUM_ID
group by ims.STADIUM_ID;

-- 3.	In a given stadium, what is the percentage of wins by a team which has won the toss?

select ist.STADIUM_ID,STADIUM_NAME,
count(case when TOSS_WINNER = MATCH_WINNER then 1 end) as Toss_win ,
count(im.match_id) as total_match,
round((count(case when TOSS_WINNER = MATCH_WINNER then 1 end) / count(im.match_id) ) * 100,2) as percent_wins 
from ipl_match im 
join ipl_match_schedule ims
on ims.MATCH_ID=im.MATCH_ID
join ipl_stadium ist
on ist.STADIUM_ID=ims.STADIUM_ID
group by 1,2;

-- 4.	Show the total bids along with the bid team and team name.

select BID_TEAM,team_name,count(bid_team) as total_bids
from ipl_bidding_details ibd join ipl_team it
on it.TEAM_ID=ibd.BID_TEAM
group by 1,2;

-- 5.	Show the team id who won the match as per the win details.

select 
	MATCH_ID, 
	case when MATCH_WINNER = 1  or MATCH_WINNER = TEAM_ID1 then TEAM_ID1 
    when MATCH_WINNER = 2 or MATCH_WINNER = TEAM_ID2 then team_ID2 end as winner_Team_ID
	from  ipl_match;
    
 -- 6.	Display total matches played, total matches won and total matches lost by the team along with its team name.

with t as( 
select
MATCH_ID, 
	case when MATCH_WINNER = 1  or MATCH_WINNER = TEAM_ID1 then TEAM_ID1 
    when MATCH_WINNER = 2 or MATCH_WINNER = TEAM_ID2 then team_ID2 end as winner_Team_ID
	from  ipl_match)
select 
	team_id,
	team_name,
    ((select count(team_id1) from ipl_match where team_id1 = it.team_id) + (select count(team_id2) from ipl_match where team_id2 = it.team_id) ) as total_match,
    (select count(match_id) from t where winner_team_id = it.team_id) as matches_won,
    (((select count(team_id1) from ipl_match where team_id1 = it.team_id) + (select count(team_id2) from ipl_match where team_id2 = it.team_id) ) -(select count(match_id) from t where winner_team_id = it.team_id) ) match_lost
from ipl_team it;

-- 7.	Display the bowlers for the Mumbai Indians team.
SELECT * FROM ipl.ipl_team_players
where player_role = 'Bowler' and TEAM_ID = (select team_id from ipl_team where team_name like '%MUMBAI%');

-- 	8.	How many all-rounders are there in each team, Display the teams with more than 4 
-- all-rounders in descending order.

select 
	team_id , 
    team_name, 
    (select count(player_id) from ipl_team_players
			where player_role like '%ALL%' and team_id = it.team_id) as No_of_allrounders
from 
	ipl_team it
where 	
		(select count(player_id) from ipl_team_players
				where player_role like '%ALL%' and team_id = it.team_id)  > 4
order by 3 desc ;

/* 9.  Write a query to get the total bidders points for each bidding status of those bidders who bid on CSK 
when it won the match in M. Chinnaswamy Stadium bidding year-wise.
 Note the total bidders’ points in descending order and the year is bidding year.
               Display columns: bidding status, bid date as year, total bidder’s points
*/

SELECT * FROM ipl.ipl_match_schedule ims
join ipl_bidding_details ibd
on ims.SCHEDULE_ID = ibd.SCHEDULE_ID
join ipl_stadium ist
on ist.STADIUM_ID = ims.STADIUM_ID
join ipl_match im
on im.MATCH_ID = ims.MATCH_ID
where STADIUM_NAME like '%Chinnaswamy%' and	 win_details like '%CSK%';

/*
10.	Extract the Bowlers and All Rounders those are in the 5 highest number of wickets.
Note 
1. use the performance_dtls column from ipl_player to get the total number of wickets
 2. Do not use the limit method because it might not give appropriate results when players have the same number of wickets
3.	Do not use joins in any cases.
4.	Display the following columns teamn_name, player_name, and player_role.
*/
with t as (
SELECT
	(select team_name from ipl_team where team_id = (select team_id  from ipl_team_players where PLAYER_ID =ip.PLAYER_ID) ) as team_name,
	player_name,
    (select player_role from ipl_team_players where player_id = ip.PLAYER_ID) as player_role,
	cast(TRIM(substr(PERFORMANCE_DTLS,INSTR(PERFORMANCE_DTLS,'wkt')+4,2)) as unsigned) AS WICKETS,
	dense_rank() over( order by cast(TRIM(substr(PERFORMANCE_DTLS,INSTR(PERFORMANCE_DTLS,'wkt')+4,2)) as unsigned) desc) rk
FROM ipl.ipl_player ip
Where PLAYER_ID in (select PLAYER_ID from ipl_team_players where player_role in ('Bowler','All-Rounder')))
SELECT 
    *
FROM
    t
WHERE
    rk < 6;

          
/*
11.	show the percentage of toss wins of each bidder and display the results in descending order based on the percentage

*/
            
with t as(
SELECT BIDDER_ID,bid_team,
case when TOSS_WINNER = 1 then TEAM_ID1 else TEAM_ID2 end as toss_win_team FROM ipl.ipl_bidding_details ibd
join ipl_match_schedule ims
on ims.SCHEDULE_ID = ibd.SCHEDULE_ID
join ipl_match im
on im.MATCH_ID =ims.MATCH_ID)

select 
	bidder_id , 
	count(case when bid_team = toss_win_team then 1 else null end) as bid_team_toss,
    count(bid_team) as total_bids ,
    count(case when bid_team = toss_win_team then 1 else null end) /  count(bid_team) * 100 as percent_toss_wins
from t
group by 1;
;



-- 12.	find the IPL season which has min duration and max duration.
-- Output columns should be like the below:
-- Tournment_ID, Tourment_name, Duration column, Duration

 
SELECT 
    tournmt_id,
    tournmt_name,
    DATEDIFF(to_date, From_date) duration
FROM
    ipl.ipl_tournament
WHERE
    DATEDIFF(to_date, From_date) = (SELECT 
            MIN(DATEDIFF(to_date, From_date))
        FROM
            ipl_tournament)
        OR DATEDIFF(to_date, From_date) = (SELECT 
            MAX(DATEDIFF(to_date, From_date)) AS max_dur
        FROM
            ipl_tournament);
  
/*

13.	Write a query to display to calculate the total points month-wise for the 2017 bid year. sort the results based on total points in descending order and month-wise in ascending order.
Note: Display the following columns:
1.	Bidder ID, 2. Bidder Name, 3. bid date as Year, 4. bid date as Month, 5. Total points
Only use joins for the above query queries.

*/

select * from ipl_bidder_details;
select * from ipl_bidder_points;
select * from ipl_bidding_details;
desc ipl_bidding_details;

select distinct bdr.BIDDER_ID,bdr.BIDDER_NAME,year(bdg.BID_DATE) as Year,month(bdg.BID_DATE) as Month,pts.TOTAL_POINTS as Total_Points
from ipl_bidder_details bdr inner join ipl_bidder_points pts
on bdr.BIDDER_ID=pts.BIDDER_ID 
inner join ipl_bidding_details bdg
on pts.BIDDER_ID=bdg.BIDDER_ID
where year(bdg.BID_DATE)=2017
order by Total_Points desc,Month asc ;

/**14. Write a query to display to calculate the total points month-wise for the 2017 bid year. sort the results based on total 
points in descending order and month-wise in ascending order.
Note: Display the following columns:
1. Bidder ID, 2. Bidder Name, 3. bid date as Year, 4. bid date as Month, 5. Total points
Don't use joins for the above query queries.**/

select * from ipl_bidder_details;
select * from ipl_bidder_points;
select * from ipl_bidding_details;
desc ipl_bidding_details;

select bidder_id, (select bidder_name from ipl_bidder_details where ipl_bidder_details.bidder_id=ipl_bidding_details.bidder_id) as bidder_name,
year(bid_date) as `year`, monthname(bid_date) as `month`, 
(select total_points from ipl_bidder_points where ipl_bidder_points.bidder_id=ipl_bidding_details.bidder_id) as total_points from ipl_bidding_details
where year(bid_date)=2017
group by bidder_id,bidder_name,year,month,total_points
order by total_points desc;




/*
15.	Write a query to get the top 3 and bottom 3 bidders based on the total bidding points for the 2018 bidding year.
Output columns should be:
like:
Bidder Id, Ranks (optional), Total points, Highest_3_Bidders --> columns contains name of bidder, Lowest_3_Bidders  --> columns contains name of bidder;


*/

with t as(
SELECT *,DENSE_RANK() over(order by total_points  desc ) rk
 FROM ipl.ipl_bidder_points),
 
t1 as(
select 
	bidder_id,
    total_points,
    rk,
	case when rk between 1 and 3 then bidder_id else null end as highest_bidder,
    case when rk between (select max(rk) from t)-2 and (select max(rk) from t) then bidder_id else null end as lowest_bidders
from t 
where 
	(case when rk between 1 and 3 then bidder_id else null end)  is not null
		or  ( case when rk between (select max(rk) from t)-2 and (select max(rk) from t) then bidder_id else null end ) is not null
			)

select 
	bidder_id,
	total_points , 
    (select bidder_name from ipl_bidder_details where bidder_id = t1.highest_bidder) as highest_bidder,
    (select bidder_name from ipl_bidder_details where bidder_id = t1.lowest_bidders) as lowest_bidder
    from t1
    ;
    
-- 16. Create two tables called Student_details and Student_details_backup.

-- Create the Student_details table
CREATE TABLE Student_details (
    Student_id INT PRIMARY KEY,
    Student_name VARCHAR(255),
    Mail_id VARCHAR(255),
    Mobile_no VARCHAR(15)
);

-- Create the Student_details_backup table
CREATE TABLE Student_details_backup (
    Student_id INT PRIMARY KEY,
    Student_name VARCHAR(255),
    Mail_id VARCHAR(255),
    Mobile_no VARCHAR(15),
    Backup_timestamp TIMESTAMP
);

