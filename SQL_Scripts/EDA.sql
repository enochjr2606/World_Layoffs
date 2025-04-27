/* 
  -------------------------------------------------------------------------------
EXPLORATORY DATA ANALYSIS (EDA) on the 'layoffs_staging2' table to understand layoffs trends and statistics
across various categories.
These queries provide insights into the scale, trends, and key contributors to layoffs over time and across
different groups.


AUTHOR: [Nuhu Enoch]
  -------------------------------------------------------------------------------
*/

-- Display all records from the layoffs_staging2 table
SELECT *
FROM world_layoffs.layoffs_staging2;

-- Get the maximum total laid off and the maximum percentage laid off
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM world_layoffs.layoffs_staging2;

-- Select records where the percentage laid off equals 100% and order by total laid off
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- Get the total laid off by each company and order by total laid off in descending order
SELECT company, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- Get the earliest and latest dates from the data
SELECT MIN(`date`), MAX(`date`)
FROM world_layoffs.layoffs_staging2;

-- Get the total laid off by industry and order by total laid off in descending order
SELECT industry, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- Get the total laid off by country and order by total laid off in descending order
SELECT country, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- Get the total laid off by year and order by year in descending order
SELECT YEAR(`date`), SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- Get the total laid off by stage and order by total laid off in descending order
SELECT stage, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- Get the total laid off by month and order by month in ascending order
SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) 
FROM world_layoffs.layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC;

-- Calculate a rolling total of laid off employees by month
WITH Rolling_Total AS
    (
        SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS Total_Off
        FROM world_layoffs.layoffs_staging2
        WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
        GROUP BY `MONTH`
        ORDER BY 1 ASC
    )
SELECT `MONTH`, Total_Off,
    SUM(Total_Off) OVER (ORDER BY `MONTH`) AS Roll_Total
FROM Rolling_Total;

-- Get the total laid off by company and year and order by company in ascending order
SELECT company, YEAR(`date`) AS `Year`, SUM(total_laid_off) AS Sum_Total_LaidOff
FROM world_layoffs.layoffs_staging2
GROUP BY company, `year`
ORDER BY 1 ASC;

-- Rank companies by total laid off per year and select top 5 ranked companies per year
WITH Company_Year (Company, `Year`, Total_laid_off) AS
(
    SELECT company, YEAR(`date`) AS `Year`, SUM(total_laid_off) AS Sum_Total_LaidOff
    FROM world_layoffs.layoffs_staging2
    GROUP BY company, `year`
),
Company_Year_Rank AS
(
    SELECT *, DENSE_RANK() OVER (PARTITION BY `Year` ORDER BY Total_laid_off DESC) AS Ranking
    FROM Company_Year
    WHERE `Year` IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;
