/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1.

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */


ANSWER 1:

SELECT name FROM Facilities WHERE membercost = 0;



/* Q2: How many facilities do not charge a fee to members? */


ANSWER 2:

SELECT COUNT(*) FROM Facilities WHERE membercost = 0;

--Answer: 4



/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */


ANSWER 3:

SELECT facid, name, membercost, monthlymaintenance FROM Facilities WHERE membercost != 0 AND membercost < .2*(monthlymaintenance);

--The member cost for facilities that do cost members is less than 20% of the respective facility for ALL 5 facilities that charge members




/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */


ANSWER 4: 

SELECT * FROM Facilities WHERE facid IN (1,5);

--IN function is a quicker alternative to OR




/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */


ANSWER 5:

SELECT name, monthlymaintenance,
CASE WHEN monthlymaintenance < 100 THEN 'cheap'
ELSE 'expensive'
END AS maintenance_costliness
FROM Facilities;

--utilized CASEs




/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */


ANSWER 6:

SELECT firstname, surname, MAX(joindate)
FROM Members;

--Also tried, but got errors:

/*
SELECT firstname, surname,
RANK() OVER(ORDER BY joindate DESC) AS joindate_rank
FROM Members;

SELECT firstname, surname,
FROM Members
WHERE joindate = MAX(joindate);

SELECT firstname, surname,
FROM Members
WHERE joindate IN MAX(joindate);


SELECT firstname, surname,
FROM Members
WHERE joindate =
(SELECT MAX(joindate)
 FROM Members);


SELECT firstname, surname,
FROM Members
WHERE joindate IN
(SELECT MAX(joindate)
 FROM Members);
*/



/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */


ANSWER 7:

SELECT DISTINCT CONCAT(firstname, surname) AS member_full_name, Facilities.name
FROM Bookings
JOIN Members USING(memid)
JOIN Facilities USING(facid)
WHERE Facilities.name LIKE('Tennis%')
ORDER BY member_full_name;


--This kept giving errors (Error in Processing Request, Error code: 403, Error text: error'). Doesn't seem to like CONCAT?


--So best could do that worked was this:

SELECT DISTINCT firstname, surname, Facilities.name AS facility
FROM Bookings
JOIN Members USING(memid)
JOIN Facilities USING(facid)
WHERE Facilities.name LIKE('Tennis%')
ORDER BY surname, facility;




/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */


ANSWER 8:

SELECT CONCAT(firstname, surname) AS member_full_name, Facilities.name AS facility
CASE WHEN memid = 0 THEN 'guest'
ELSE 'member'
END AS person_type,
CASE WHEN memid = 0 THEN guestcost*slots
ELSE membercost*slots
END AS total_cost
FROM Bookings
JOIN Members USING(memid)
JOIN Facilities USING(facid)
WHERE DATE(Bookings.starttime) = '2012-09-14'
	  AND ((memid = 0 AND guestcost*slots > 30)
	  OR   (memid != 0 AND membercost*slots > 30))
ORDER BY cost DESC;

--Again errors with this^. Modified to work:

SELECT firstname, surname, Facilities.name AS facility,
CASE WHEN memid = 0 THEN 'guest'
ELSE 'member'
END AS person_type,
CASE WHEN memid = 0 THEN guestcost*slots
ELSE membercost*slots
END AS total_cost
FROM Bookings
JOIN Members USING(memid)
JOIN Facilities USING(facid)
WHERE DATE(Bookings.starttime) = '2012-09-14'
	  AND ((memid = 0 AND guestcost*slots > 30)
	  OR   (memid != 0 AND membercost*slots > 30))
ORDER BY cost DESC;





/* Q9: This time, produce the same result as in Q8, but using a subquery. */


ANSWER 9:

--Challenged self to not use any joins. Couldn't think of clean ways
--Code limited for same reasons as above

SELECT
(SELECT firstname
 FROM Members
 WHERE Bookings.memid = Members.memid) AS first_name,
(SELECT surname
 FROM Members
 WHERE Bookings.memid = Members.memid) AS surname,
(SELECT name
 FROM Facilities
 WHERE Bookings.facid = Facilities.facid) AS facility,
(SELECT guestcost
 FROM Facilities
 WHERE guestcost > 30 AND Bookings.facid = Facilities.facid) as guest_cost
FROM Bookings
WHERE DATE(Bookings.starttime) = '2012-09-14';




/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */


ANSWER 10:

import pandas as pd
import sqlite3 as sql
countryclub_db = 'sqlite_db_pythonsqlite.db'
connection = sql.connect(countryclub_db)
query = 'SELECT facility, SUM(total_cost) AS revenue FROM (SELECT firstname, surname, Facilities.name AS facility, CASE WHEN memid = 0 THEN "guest"ELSE "member" END AS person_type, CASE WHEN memid = 0 THEN guestcost*slots ELSE membercost*slots END AS total_cost FROM Bookings JOIN Members USING(memid) JOIN Facilities USING(facid)) AS total_cost_per_booking GROUP BY facility HAVING SUM(total_cost) < 1000 ORDER BY SUM(total_cost) DESC'
df = pd.read_sql_query(query, connection)
df

#query:
# SELECT facility, SUM(total_cost) AS revenue
# FROM
# (SELECT firstname, surname, Facilities.name AS facility, CASE WHEN memid = 0 THEN "guest"
# ELSE "member" END AS person_type,
# CASE WHEN memid = 0 THEN guestcost*slots
# ELSE membercost*slots END AS total_cost
# FROM Bookings
# JOIN Members USING(memid)
# JOIN Facilities USING(facid)) AS total_cost_per_booking
# GROUP BY facility HAVING SUM(total_cost) < 1000 ORDER BY SUM(total_cost) DESC




/* Q11: Produce a report of members and who recommended them in alphabetic surname, firstname order */


ANSWER 11:

query = 'SELECT m1.firstname, m1.surname, m2.firstname AS recommendedby_firstname, m2.surname AS recommendedby_surname FROM Members AS m1 JOIN Members AS m2 ON m1.recommendedby = m2.memid WHERE m1.recommendedby !="" ORDER BY m1.surname, m1.firstname;'

df = pd.read_sql_query(query, connection)
df

#query:
# SELECT m1.firstname, m1.surname, m2.firstname AS recommendedby_firstname, m2.surname
# AS recommendedby_surname
# FROM Members AS m1
# JOIN Members AS m2
# ON m1.recommendedby = m2.memid
# WHERE m1.recommendedby !=''
# ORDER BY surname, firstname;




/* Q12: Find the facilities with their usage by members, but not guests */


ANSWER 12:

query = 'SELECT name AS facility, SUM(slots) AS member_bookings FROM Bookings JOIN Facilities USING(facid) WHERE memid !=0 GROUP BY facility ORDER BY SUM(slots) DESC;'
df = pd.read_sql_query(query, connection)
df

#query:
# SELECT name AS facility, SUM(slots) AS member_bookings
# FROM Bookings
# JOIN Facilities
# USING(facid)
# WHERE memid !=0
# GROUP BY facility
# ORDER BY SUM(slots) DESC;




/* Q13: Find the facilities usage by month, by members only, not guests */


ANSWER 13:

query = 'SELECT name AS facility, strftime("%m", starttime) AS month, SUM(slots) AS guest_bookings FROM Bookings JOIN Facilities USING(facid) WHERE memid = 0 GROUP BY facility, month ORDER BY month, SUM(slots) DESC;'

df = pd.read_sql_query(query, connection)
df

# query:
# SELECT name AS facility, EXTRACT(MONTH FROM starttime) AS month, SUM(slots) AS guest_bookings
# /* NOTE - in python/jupyter we can't use EXTRACT for some reason, at least not in this way,
# so have to use something like "strftime("%m", starttime)" instead, used above 
# FROM Bookings
# JOIN Facilities
# USING(facid)
# WHERE memid = 0
# GROUP BY facility, month
# ORDER BY month, SUM(slots) DESC;




