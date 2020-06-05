-- Create First Tables just to upload data 
CREATE TABLE Links_CSV (
	movie_id INT,
	imdb_id VARCHAR(10), 
	tmdb_id INT
);

CREATE TABLE Keywords_CSV (
	tmdb_id INT,
	keywords TEXT
);

CREATE TABLE Ratings_CSV (
	user_id INT,
	movie_id INT,
	rating NUMERIC(3, 1), 
	rating_timestamp VARCHAR(20)
);

CREATE TABLE Metadata_CSV (
	adult VARCHAR(10),
	belongs_to_collection TEXT,
	budget INT,
	genres TEXT,
	homepage VARCHAR(500),
	tmdb_id INT,
	imdb_id VARCHAR(10),
	original_language VARCHAR(5),
	original_title VARCHAR(200),
	overview TEXT,
	popularity NUMERIC(9, 6),
	poster_path VARCHAR(200),
	production_companies TEXT,
	production_countries TEXT,
	release_date DATE,
	revenue BIGINT,
	runtime INT,
	spoken_languages TEXT,
	status VARCHAR(20),
	tagline VARCHAR(500),
	title VARCHAR(500),
	video VARCHAR(10),
	vote_average DECIMAL(3, 1),
	vote_count INT
);

CREATE TABLE Credits_CSV (
	casts TEXT,
	crews TEXT,
	tmdb_id INT
);

-- Create Tables from JSON fields (Only the ones I need for PartB)

	-- 	Create a Copy of Metadata Table
	CREATE TABLE Metadata_BACKUP
	AS (SELECT * FROM Metadata_CSV)

	--  Prepare column genres to be casted in JSON type
	UPDATE Metadata_BACKUP
	SET genres = DOUBLEQUOTE.doubles
	FROM (SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(genres, ': ''', ': "'),''',', '",'), '{''', '{"'),'''}', '"}'), ', ''', ', "'),''':', '":') AS doubles, tmdb_id FROM Metadata_BACKUP) AS DOUBLEQUOTE
	WHERE Metadata_BACKUP.tmdb_id = DOUBLEQUOTE.tmdb_id;

	-- 	Cast to JSON
	ALTER TABLE Metadata_BACKUP
	ALTER COLUMN genres TYPE JSON USING genres::JSON

	-- 	Create the in-between table for many-many relationship
	CREATE TABLE Metadata_Genres 
	AS (SELECT JS.tmdb_id, CAST(JS.genres->>'id' AS INT) AS genre_id, CAST(JS.genres->>'name' AS VARCHAR(50)) AS genre_name FROM
			(SELECT tmdb_id, json_array_elements(genres) AS genres FROM Metadata_BACKUP) AS JS)

	--  Finally, Create Genres Table
	CREATE TABLE Genres 
	AS (SELECT DISTINCT genre_id, genre_name FROM Metadata_Genres)
	
	-- 	Create the appropriate constraints
	ALTER TABLE Genres ADD PRIMARY KEY(genre_id)
	ALTER TABLE Metadata_BACKUP RENAME TO Metadata
	ALTER TABLE Metadata ADD PRIMARY KEY(tmdb_id)
	ALTER TABLE Metadata_Genres DROP COLUMN genre_name
	ALTER TABLE Metadata_Genres ADD FOREIGN KEY(genre_id) REFERENCES Genres(genre_id)
	ALTER TABLE Metadata_Genres ADD FOREIGN KEY(tmdb_id) REFERENCES Metadata(tmdb_id)											   

	-- 	Drop genres column from Metadata 
	ALTER TABLE Metadata DROP COLUMN genres

	-- Create Links
		-- Keep ONLY the fields that appear in Metadata too
		CREATE TABLE Links 
			AS (SELECT Links_CSV.movie_id, Links_CSV.imdb_id, Links_CSV.tmdb_id FROM Links_CSV
			   JOIN Metadata
			   ON Metadata.tmdb_id = Links_CSV.tmdb_id)																	   

		ALTER TABLE Links ADD PRIMARY KEY(movie_id)

	-- Create Credits
		-- Keep ONLY the fields that appear in Metadata too
		CREATE TABLE Credits 
			AS (SELECT Credits_CSV.tmdb_id, Credits_CSV.casts, Credits_CSV.crews FROM Credits_CSV
			   JOIN Metadata
			   ON Metadata.tmdb_id = Credits_CSV.tmdb_id)																	   

		ALTER TABLE Credits ADD FOREIGN KEY(tmdb_id) REFERENCES Metadata(tmdb_id)																	   
																		   
	
	-- Create Keywords
		-- Keep ONLY the fields that appear in Metadata too
		CREATE TABLE Keywords 
			AS (SELECT Keywords_CSV.tmdb_id, Keywords_CSV.keywords FROM Keywords_CSV
			   JOIN Metadata
			   ON Metadata.tmdb_id = Keywords_CSV.tmdb_id)																	   

		ALTER TABLE Keywords ADD PRIMARY KEY(tmdb_id)								   
 
	-- Create Ratings
	CREATE TABLE Ratings 
	AS (SELECT * FROM Ratings_CSV)

	ALTER TABLE Ratings 
	ALTER COLUMN rating_timestamp TYPE INT USING rating_timestamp::INT

	ALTER TABLE Ratings 
	ADD COLUMN date_time TIMESTAMP WITH TIME ZONE

	UPDATE Ratings
	SET date_time = TO_TMSTMP.date_time
	FROM (SELECT TO_TIMESTAMP(rating_timestamp) AS date_time, rating_timestamp, movie_id, user_id FROM Ratings) AS TO_TMSTMP
	WHERE Ratings.rating_timestamp = TO_TMSTMP.rating_timestamp AND Ratings.movie_id = TO_TMSTMP.movie_id AND Ratings.user_id = TO_TMSTMP.user_id

	ALTER TABLE Ratings 
	DROP COLUMN rating_timestamp

	ALTER TABLE Ratings 
	ADD PRIMARY KEY(user_id, movie_id, date_time)

-- Edit Data Types 

ALTER TABLE Metadata
ALTER COLUMN video TYPE BOOL USING CASE WHEN video = 'FALSE' THEN FALSE ELSE TRUE END,
ALTER COLUMN adult TYPE BOOL USING CASE WHEN adult = 'FALSE' THEN FALSE ELSE TRUE END;	

-- Correct imdb_id from the actual API
UPDATE Links 
SET imdb_id = CORRECT.imdb_id
FROM (SELECT CONCAT('tt', imdb_id) AS imdb_id, tmdb_id FROM Links) AS CORRECT																		   
WHERE Links.tmdb_id = CORRECT.tmdb_id

 
-- Create additional Tables to make it a little bit closer to BCNF
	
-- Create Companies
	-- 	Create a Copy of Metadata Table
	CREATE TABLE Metadata_BACKUP
	AS (SELECT * FROM Metadata)

	--  Prepare column production_companies so it can be casted in JSON type
	UPDATE Metadata_BACKUP
	SET production_companies = DOUBLEQUOTE.doubles
	FROM (SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(production_companies, '"', ''''), '''name'': ''', '"name": "'),''', ''', '", "'), '{''', '{"'),''':', '":'), '"name": ""', '"name": "'), '\xa0', '') AS doubles, tmdb_id FROM Metadata_BACKUP) AS DOUBLEQUOTE
	WHERE Metadata_BACKUP.tmdb_id = DOUBLEQUOTE.tmdb_id;

	-- 	Cast to JSON
	ALTER TABLE Metadata_BACKUP
	ALTER COLUMN production_companies TYPE JSON USING production_companies::JSON

	-- 	Create the in-between table for many-many relationship
	CREATE TABLE Metadata_Companies 
	AS (SELECT JS.tmdb_id, CAST(JS.production_companies->>'id' AS INT) AS company_id, CAST(JS.production_companies->>'name' AS VARCHAR(50)) AS company_name FROM
			(SELECT tmdb_id, json_array_elements(production_companies) AS production_companies FROM Metadata_BACKUP) AS JS)

	--  Finally, Create Production_Companies Table
	CREATE TABLE Production_Companies  
	AS (SELECT DISTINCT company_id, company_name FROM Metadata_Companies)

	-- 	Drop columns from the in-between Table
	ALTER TABLE Metadata_Companies DROP COLUMN company_name
	ALTER TABLE Metadata DROP COLUMN production_companies
	ALTER TABLE Production_Companies ADD PRIMARY KEY(company_id)
	ALTER TABLE Metadata_Companies ADD FOREIGN KEY(company_id) REFERENCES Production_Companies(company_id)
	ALTER TABLE Metadata_Companies ADD FOREIGN KEY(tmdb_id) REFERENCES Metadata(tmdb_id)



-- Create Countries
-- Create a Copy of Metadata Table
	CREATE TABLE Metadata_BACKUP
	AS (SELECT * FROM Metadata)

	--  Prepare column production_countries so it can be casted in JSON type
	UPDATE Metadata_BACKUP
	SET production_countries = DOUBLEQUOTE.doubles
	FROM (SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(production_countries, '''iso_3166_1'': ''', '"iso_3166_1": "'), '''name'': ''', '"name": "'),''', ''', '", "'), '{''', '{"'), '''}', '"}'), ''', "', '", "'),  ''': "', '": "') AS doubles, tmdb_id FROM Metadata_BACKUP) AS DOUBLEQUOTE
	WHERE Metadata_BACKUP.tmdb_id = DOUBLEQUOTE.tmdb_id;

	-- 	Cast to JSON
	ALTER TABLE Metadata_BACKUP
	ALTER COLUMN production_countries TYPE JSON USING production_countries::JSON

	-- 	Create the in-between table for many-many relationship
	CREATE TABLE Metadata_Countries
	AS (SELECT JS.tmdb_id, CAST(JS.production_countries->>'iso_3166_1' AS VARCHAR(2)) AS country_id, CAST(JS.production_countries->>'name' AS VARCHAR(50)) AS country_name FROM
			(SELECT tmdb_id, json_array_elements(production_countries) AS production_countries FROM Metadata_BACKUP) AS JS)

	--  Finally, Create Prodution_Countries Table
	CREATE TABLE Production_Countries  
	AS (SELECT DISTINCT country_id, country_name FROM Metadata_Countries)

	-- 	Drop columns from the in-between Table
	ALTER TABLE Metadata_Countries DROP COLUMN country_name
	ALTER TABLE Metadata DROP COLUMN production_countries
	ALTER TABLE Production_Countries ADD PRIMARY KEY(country_id)
	ALTER TABLE Metadata_Countries ADD FOREIGN KEY(country_id) REFERENCES Production_Countries(country_id)
	ALTER TABLE Metadata_Countries ADD FOREIGN KEY(tmdb_id) REFERENCES Metadata(tmdb_id)



-- Create Languages
-- Create a Copy of Metadata Table
	CREATE TABLE Metadata_BACKUP
	AS (SELECT * FROM Metadata)

	--  Prepare column spoken_languages so it can be casted in JSON type
	UPDATE Metadata_BACKUP
	SET spoken_languages = DOUBLEQUOTE.doubles
	FROM (SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(spoken_languages, '''iso_639_1'': ''', '"iso_639_1": "'), '''name'': ''', '"name": "'),''', ''', '", "'), '{''', '{"'), '''}', '"}'), ''', "', '", "'),  ''': "', '": "'), '\x', '') AS doubles, tmdb_id FROM Metadata_BACKUP) AS DOUBLEQUOTE
	WHERE Metadata_BACKUP.tmdb_id = DOUBLEQUOTE.tmdb_id;

	-- 	Cast to JSON
	ALTER TABLE Metadata_BACKUP
	ALTER COLUMN spoken_languages TYPE JSON USING spoken_languages::JSON

	-- 	Create the in-between table for many-many relationship
	CREATE TABLE Metadata_Languages
	AS (SELECT JS.tmdb_id, CAST(JS.spoken_languages->>'iso_639_1' AS VARCHAR(2)) AS language_id, CAST(JS.spoken_languages->>'name' AS VARCHAR(20)) AS language_name FROM
			(SELECT tmdb_id, json_array_elements(spoken_languages) AS spoken_languages FROM Metadata_BACKUP) AS JS)

	--  Finally, Create Spoken_Languages Table
	CREATE TABLE Spoken_Languages  
	AS (SELECT DISTINCT language_id, language_name FROM Metadata_Languages)

	-- 	Drop columns from the in-between Table
	ALTER TABLE Metadata_Languages DROP COLUMN language_name
	ALTER TABLE Metadata DROP COLUMN spoken_languages
	ALTER TABLE Spoken_Languages ADD PRIMARY KEY(language_id)
	ALTER TABLE Metadata_Languages ADD FOREIGN KEY(language_id) REFERENCES Spoken_Languages(language_id)
	ALTER TABLE Metadata_Languages ADD FOREIGN KEY(tmdb_id) REFERENCES Metadata(tmdb_id)

	

-- Create Keywords
-- Create a Copy of Metadata Table
	ALTER TABLE Keywords RENAME TO Keywords_BACKUP
	CREATE TABLE Keywords_Temp
	AS (SELECT * FROM Keywords_BACKUP)

	--  Prepare column keywords so it can be casted in JSON type
	UPDATE Keywords_TEMP
	SET keywords = DOUBLEQUOTE.doubles
	FROM (SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(keywords, '''name'': ''', '"name": '),', ''', ', "'), '{''', '{"'),''':', '":'), '"name": ', '"name": "'), '\xa0', ''), '''}', '}'),  '}', '"}') AS doubles, tmdb_id FROM Keywords_TEMP) AS DOUBLEQUOTE
	WHERE Keywords_TEMP.tmdb_id = DOUBLEQUOTE.tmdb_id;

	-- 	Cast to JSON
	ALTER TABLE Keywords_TEMP
	ALTER COLUMN keywords TYPE JSON USING keywords::JSON

	-- 	Create the in-between table for many-many relationship
	CREATE TABLE Metadata_Keywords
	AS (SELECT JS.tmdb_id, CAST(JS.keywords->>'id' AS INT) AS keyword_id, CAST(JS.keywords->>'name' AS VARCHAR(50)) AS keyword_name FROM
			(SELECT tmdb_id, json_array_elements(keywords) AS keywords FROM Keywords_TEMP) AS JS)

	--  Finally, Create Keywords Table
	CREATE TABLE Keywords  
	AS (SELECT DISTINCT keyword_id, keyword_name FROM Metadata_Keywords)

	-- 	Drop columns from the in-between Table
	ALTER TABLE Metadata_Keywords DROP COLUMN keyword_name
	ALTER TABLE Keywords ADD PRIMARY KEY(keyword_id)
	ALTER TABLE Metadata_Keywords ADD FOREIGN KEY(keyword_id) REFERENCES Keywords(keyword_id)
	ALTER TABLE Metadata_Keywords ADD FOREIGN KEY(tmdb_id) REFERENCES Metadata(tmdb_id)


-- ADD all constraints that we forgot
ALTER TABLE Links ADD FOREIGN KEY(tmdb_id) REFERENCES Metadata(tmdb_id)																		   

CREATE TABLE Ratings_TEMP
AS (SELECT Ratings.user_id, Ratings.movie_id, Ratings.rating, Ratings.date_time FROM Ratings
		JOIN Links
		ON Links.movie_id = Ratings.movie_id
		JOIN Metadata
		ON Metadata.tmdb_id = Links.tmdb_id)

DROP TABLE Ratings
ALTER TABLE Ratings_TEMP RENAME TO Ratings
ALTER TABLE Ratings 
ADD PRIMARY KEY(user_id, movie_id, date_time),																		   
ADD FOREIGN KEY(movie_id) REFERENCES Links(movie_id)	

-- DROP all assisting Tables
DROP TABLE Keywords_BACKUP
DROP TABLE Keywords_CSV
DROP TABLE Keywords_TEMP
DROP TABLE Links_CSV
DROP TABLE Metadata_CSV
DROP TABLE Ratings_CSV