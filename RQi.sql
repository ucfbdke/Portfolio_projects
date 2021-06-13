SELECT TOP(100) *
FROM Thrive..May

-- Count completion in each month.
SELECT FORMAT(EndDate, 'yyyy-MM') AS Date1, FORMAT(EndDate, 'MMMM yyyy') AS Date2, COUNT(ID) AS No_of_completions
FROM Thrive..May
GROUP BY FORMAT(EndDate, 'yyyy-MM'), FORMAT(EndDate, 'MMMM yyyy')
ORDER BY Date1 ASC;

-- Count completion in each month in a period.
SELECT FORMAT(EndDate, 'yyyy-MM') AS date, FORMAT(EndDate, 'MMMM yyyy') AS Date2, COUNT(ID) AS No_of_completions 
FROM Thrive..May
WHERE EndDate BETWEEN '2020-09-01' AND '2021-06-01'
GROUP BY FORMAT(EndDate, 'yyyy-MM'), FORMAT(EndDate, 'MMMM yyyy')
ORDER BY 1 ASC;

-- 3-month and 12-month running average
;WITH Comp_count(date, No_of_completions) AS
(SELECT FORMAT(EndDate, 'yyyy-MM') AS date, COUNT(*) AS No_of_completions 
FROM Thrive..May
GROUP BY FORMAT(EndDate, 'yyyy-MM'))
SELECT date, No_of_completions, ROUND(AVG(No_of_completions) OVER(ORDER BY date ASC ROWS 2 PRECEDING),0) AS three_moving_average, ROUND(AVG(No_of_completions) OVER(ORDER BY date ASC ROWS 11 PRECEDING),0) AS twelve_moving_average
FROM Comp_count

-- Seasonality (Count per month and average per month)
;WITH avg_season(Months_num, Months, number) AS
(SELECT FORMAT(EndDate, 'MM') AS Months_num, FORMAT(EndDate, 'MMMM yyyy') AS Months, COUNT(*) AS number
FROM Thrive..May
GROUP BY FORMAT(EndDate, 'MM'), FORMAT(EndDate, 'MMMM yyyy'))
SELECT DISTINCT(avg_season.Months_num), ROUND(AVG(number) OVER(PARTITION BY avg_season.Months_num),0) AS average, season.Seasonality
FROM avg_season
INNER JOIN (
SELECT FORMAT(EndDate, 'MM') AS Months_num, FORMAT(EndDate, 'MMMM') AS Months, COUNT(*) AS Seasonality
FROM Thrive..May
GROUP BY FORMAT(EndDate, 'MM'), FORMAT(EndDate, 'MMMM')
) AS season
ON avg_season.Months_num = season.Months_num