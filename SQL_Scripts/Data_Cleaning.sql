/* 
-------------------------------------------------------------------------------
Data cleaning process for the layoffs dataset:
- Create backup tables to preserve original data.
- Identify and remove duplicate records using ROW_NUMBER().
- Standardize values in key columns like company, industry, country, and date.
- Convert date values into proper DATE format.
- Handle NULL and blank values by updating or deleting records as needed.
- Drop helper columns used during the cleaning process.
This ensures a clean, consistent dataset ready for analysis.
-------------------------------------------------------------------------------
*/

-- DATA CLEANING --
-- SET SQL_SAFE_UPDATES = 0;
SELECT *
FROM layoffs;

SELECT *
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2;

-- Creating a backup table
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT INTO layoffs_staging    -- Copying data from layoffs table to layoffs_staging table
SELECT *
FROM layoffs;


-- 1. REMOVING DUPLICATES

WITH duplicate_cte AS      -- Checking if duplicates exist
(
	SELECT*,
    ROW_NUMBER() OVER
		(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`,
        stage, country, funds_raised_millions) AS row_num
	FROM
		world_layoffs.layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

    
CREATE TABLE `layoffs_staging2` (  -- Creating another table and adding row_num column that we will delete the duplicate from
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


INSERT INTO layoffs_staging3        -- Inserting the data into our new table layoffs_staging2 
SELECT*,
    ROW_NUMBER() OVER
		(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`,
        stage, country, funds_raised_millions) AS row_num
	FROM
		world_layoffs.layoffs_staging;
        
    
DELETE                                      -- Deleting duplicates
FROM world_layoffs.layoffs_staging2
WHERE row_num > 1;

SELECT *                                    -- Checking to see if duplicates are deleted
FROM world_layoffs.layoffs_staging2
WHERE row_num > 1;




-- 2. STANDARDIZING DATA

-- Standardizing the column company
SELECT company, TRIM(company)
FROM world_layoffs.layoffs_staging2;

UPDATE world_layoffs.layoffs_staging2          -- Updating the column company
SET company = TRIM(company);

-- Standardizing the column industry
SELECT DISTINCT (industry)
FROM world_layoffs.layoffs_staging2
ORDER BY 1;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry LIKE "Crypto%";              -- To confirm the data properly

UPDATE world_layoffs.layoffs_staging2       -- Updating the column industry   
SET industry = "Crypto" 
WHERE industry LIKE "Crypto%";


-- Standardizing the column country
SELECT DISTINCT country                     -- Checking for error in the column country
FROM world_layoffs.layoffs_staging2
ORDER BY 1;

UPDATE world_layoffs.layoffs_staging2
SET country = trim(TRAILING '.' FROM country)   -- Updating the column country (removing the .)
WHERE country LIKE "United States%";


-- Standardizing the column date
SELECT `date`                                   -- Checking the date column
FROM world_layoffs.layoffs_staging2;

SELECT `date`,                                   -- Using the correct date format to compare to the first date
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM world_layoffs.layoffs_staging2;

UPDATE world_layoffs.layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');   -- Updating the column to a standard date format

ALTER TABLE world_layoffs.layoffs_staging2
MODIFY COLUMN `date` DATE;                      -- Altering the table data type from text to date



-- REMOVING NULL AND BLANK VALUES
SELECT *                                        -- Trying to find the nulls or empty in industry column
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL
OR industry = '';

SELECT *
FROM world_layoffs.layoffs_staging2             -- Checking Airbnb company to see if it's value is from the same industry or not
WHERE company = "Airbnb";

SELECT t1.industry, t2.industry                 -- Joining the table to itself to check for nulls and empty values
FROM world_layoffs.layoffs_staging2 t1
JOIN world_layoffs.layoffs_staging2 t2
    ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = "")
AND t2.industry IS NOT NULL;

UPDATE world_layoffs.layoffs_staging2
SET industry = NULL                             -- Setting the industry columns values that are empty to NULL
WHERE industry = '';

UPDATE world_layoffs.layoffs_staging2 t1
JOIN world_layoffs.layoffs_staging2 t2          -- Updating and populating the industry column in t1 that are will null values
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT *
FROM world_layoffs.layoffs_staging2             -- Checking for NULL values in total_laid_off and percentage_laid_off column
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE                                          -- Deleting NULL values from total_laid_off and percentage_laid_off column
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

ALTER TABLE world_layoffs.layoffs_staging2
DROP COLUMN row_num;                            -- Deleting row_num column
