-- BUSINESS REQUEST -1 :- CITY-LEVEL FARE AND TRIP SUMMARY REPORT 
-- GENERATE A REPORT THAT DISPLAY THE TOTAL TRIPS, AVERAGE FARE PER KM, AVERAGE FARE PER TRIP, AND THE PERCENTAGE CONTRIBUTION OF EACH CITY'S TRIPS TO THE OVERALL TRIPS. THIS REPRT WILL HELP IN ASSESSING TRIP VOLUME, PRICING EFFICIENCY, AND EACH CITY'S CONTRIBUTION TO THE OVERALL TRIPS COUNT. 
-- * CITY_NAME
-- * TOTAL_TRIPS
-- * AVG_FARE_PER_TRIP


SELECT
    c.city_name,
    COUNT(trip_id) AS total_trips,
    ROUND(SUM(fare_amount) / SUM(distance_travelled(km)), 2) AS avg_fare_per_km,
    ROUND(AVG(fare_amount), 2) AS avg_fare_per_trip,
    ROUND(
        (COUNT(trip_id) * 100.0) / 
        (SELECT COUNT(trip_id) FROM fact_trips), 
        2
    ) AS trip_percentage_contribution
FROM dim_city c
JOIN fact_trips t
    ON c.city_id = t.city_id
GROUP BY c.city_name;

-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- GENERATE A REPORT THAT EVALUTES THE TARGET PEFORMANCE FOR TRIPS AT THE MONTHLY AND CITY LEVEL FOR EACH CITY AND MONTH COMPARE THE ACTUAL TOTAL TRIPS WITH THE TARGET TRIPS AND CATEGORIES THE PERFORMANCE AS FOLLOWS :
-- 1, IF ACTUAL TRIPS ARE GREATER THAN TARGET TRIPS, MARK IT AS 'ABOVE TARGET'.
-- 2, IF ACTUAL TRIPS ARE LESS THAN OR EQUAL TO TARGET TRIPS,MARK IT AS 'BELOW TARGET'. 
-- ADITIONALLY ,CALCULATE THE % DIFFERENCE BETWEEN ACTUAL AND TARGET TRIPS TO QUANTIFY THE PERFORMANCE GAP.
-- FIELDS;
-- 1.CITY_NAME, 2.MONTH_NAME, 3.ACTUAL_TRIPS, 4.TARGET_TRIPS, 5.PERFORMANCE_STATUS, 6.%_DIFFERENCE


with 
   target as ( 
      select 
         monthname(month) as month_name, city_id, total_target_trips as target_trips
	  from goodscabs.monthly_target_trips
      ),
      actual as (
      select 
        city_id,monthname(date) as month_name, count(trip_id) as actual_trips
        from fact_trips
        group by city_id,month_name
        )
        
        select
        c.city_name, a.month_name, a.actual_trips, t.target_trips,
        case 
          when actual_trips-target_trips > 0 then "above target"
          else "below target"
          end as performance_status,
          round(100*(a.actual_trips-target_trips)/target_trips,2) as pc_diff
          from actual a 
          join target t 
          on a.city_id = t.city_id
          and a.month_name = t.month_name
          join dim_city c
          on a.city_id = c.city_id
          order by city_name, month_name;
          
		
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------    
        
   -- bussiness request - 3 :- city-level repeat passrnger trip frequency report
   
   -- Generate a report that show the percentage distribution of repeat passengers by the number of trips they taken in each city. calculate the percentage of repeat passengers who took 2 trips , 3 trips, and so on ,up tto 10 trips. 
   -- each column should represent a trip count category, displaying the percentage of repeat passengers who fall into that category out of the total repeat passengers for that city.this report will help identifity cities with high repeat trips frequency, which can indicate strong customer loyality or frequency usage patterns. 
   
   
   select c.city_name,
   round((sum(case when trip_count = "2-Trips" then repeat_passenger_count else 0 end)*100.0) / nullif(sum(repeat_passenger_count), 0),2) as "2-Trips",
   round((sum(case when trip_count = "3-Trips" then repeat_passenger_count else 0 end)*100.0) / nullif(sum(repeat_passenger_count), 0),2) as "3-Trips",
   round((sum(case when trip_count = "4-Trips" then repeat_passenger_count else 0 end)*100.0) / nullif(sum(repeat_passenger_count), 0),2) as "4-Trips",
   round((sum(case when trip_count = "5-Trips" then repeat_passenger_count else 0 end)*100.0) / nullif(sum(repeat_passenger_count), 0),2) as "5-Trips",
   round((sum(case when trip_count = "6-Trips" then repeat_passenger_count else 0 end)*100.0) / nullif(sum(repeat_passenger_count), 0),2) as "6-Trips",
   round((sum(case when trip_count = "7-Trips" then repeat_passenger_count else 0 end)*100.0) / nullif(sum(repeat_passenger_count), 0),2) as "7-Trips",
   round((sum(case when trip_count = "8-Trips" then repeat_passenger_count else 0 end)*100.0) / nullif(sum(repeat_passenger_count), 0),2) as "8-Trips",
   round((sum(case when trip_count = "9-Trips" then repeat_passenger_count else 0 end)*100.0) / nullif(sum(repeat_passenger_count), 0),2) as "9-Trips",
   round((sum(case when trip_count = "10-Trips" then repeat_passenger_count else 0 end)*100.0) / nullif(sum(repeat_passenger_count), 0),2) as "10-Trips"
   from 
   dim_repeat_trip_distribution r
   join dim_city c
   on r.city_id = c.city_id
   group by c.city_name
   order by c.city_name;
    
 --------------------------------------------------------------------------------------------------------------------------------------------------------------------------   
    -- bussiness request - 4 :- identitfy cities with highest and lowest total new passegers
    
    -- Generate a report that calculates the total new passegers for each city and ranks them based on this value. identify the top 3 cities with the highest number of new passeger as well as the bottom 3 cities with the lowest number of new passegers, categorising them as 'Top 3' or 'Bottom 3' accordingly. 
    
    
    with 
        city_total as ( 
            select 
             c.city_name,
             sum(new_passengers) as total_new_passengers
            from fact_passenger_summary ps
            join dim_city c
            on ps.city_id = c.city_id
            group by city_name
		),
        city_rank as (
           select 
              city_name,
              total_new_passengers,
              dense_rank() over(Order by total_new_passengers desc) as rank_desc,
              dense_rank() over(order by total_new_passengers asc) as rank_asc
		   from city_total
           ),
           city_categories as (
               select
                   city_name,
                   total_new_passengers,
                   case
                      when  rank_desc <= 3 then 'Top 3'
                      when rank_asc <= 3 then 'Bottom 3'
                      else null
					end as city_category
                from city_rank
                )
                select
                   city_name,
                   total_new_passengers,
                   city_category
                from city_categories
                where city_category is not null 
                order by total_new_passengers desc;
                
--------------------------------------------------------------------------------------------------------------------------------------------------------                

-- business request - 5 :- identify month with higest revenue for each city

-- Generate a report  that identifies the month with the highest revenue for each city. for each city, display the month_name , the revenue amount for that month, and the percentage contribution of that month's revenue to the city's total revenue. 


with 
   revenue_monthly as (
       select c.city_name, monthname(t.date) as month,
       sum(t.fare_amount) as revenue
	from fact_trips t
    join dim_city c
    on t.city_id = c.city_id 
    group by c.city_name, month 
    ),
    revenue_ranking  as (
         select 
             city_name,
             month as highest_revenue_month,
             revenue,
             dense_rank() over(partition by city_name order by revenue desc) as revenue_rank
             from revenue_monthly
    ),
	revenue_total as (
        select 
           city_name, 
           sum(revenue) as total_revenue
		from revenue_monthly 
        group by city_name
        )
	select
        r.city_name,
        r.highest_revenue_month,
        r.revenue,
        round((r.revenue/t.total_revenue)*100,2) as percentage_contribution 
	from revenue_ranking r 
    join revenue_total t
    on r.city_name = t.city_name
    where r.revenue_rank = 1;
    
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------    
    
    -- business request -6: repeat passenger rate analysis
    -- generate a report that calculate two meterics:
    -- 1.monthly report pasegers rate: calculate the repeat paasenger rate for each city and monthly by comparing the nymber of repeated passengers to the total passengers.these metrics will provides insights into monthly trendes as well as the overall repeats behaviour for each city.
    
    
    select
    c.city_name,
    monthname(p.month) as month_name,
    p.total_passengers,
    p.repeat_passengers,
    round( 
         (p.repeat_passengers*100.0/nullif(p.total_passengers,0)),
         2
         ) as monthly_repeat_passengers_rate
      from
		fact_passenger_summary p
        join dim_city c 
        on p.city_id = c.city_id
        order by c.city_name, month;
 ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------       
        
        -- business request 7 : repeat asssengers rate analysis
        -- city_wide repeat paasenger rate: calculte the overall repeat paasenger rate for each city, considering all passengers rate for each city, considering all passengers across months.  
        -- tese metrics will provides insights into monthly repeat trends as well as the overall repeats behaviour for each city
        
        
        select c.city_name,
        sum(p.total_passengers) as total_passengers,
        sum(p.repeat_passengers)as repeat_passengers,
        round( 
             (sum(p.repeat_passengers)*100.0/nullif(sum(p.total_passengers),0)),2) as city_repeat_passenger_rate
             from fact_passenger_summary p
             join dim_city c
             on p.city_id = c.city_id
             group by c.city_name
             order by city_repeat_passenger_rate desc;
             
             
   --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------          