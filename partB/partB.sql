-- Αριθμός ταινιών ανά χρόνο
SELECT date_part('year', release_date) AS year, COUNT(tmdb_id) AS movies FROM Metadata
GROUP BY year
ORDER BY year ASC


-- Αριθμός ταινιών ανά είδος(genre)
SELECT genre_name AS genre, COUNT(Metadata.tmdb_id) AS movies FROM Metadata
JOIN Metadata_Genres
ON Metadata.tmdb_id = Metadata_Genres.tmdb_id
JOIN Genres
ON Genres.genre_id = Metadata_Genres.genre_id
GROUP BY genre_name
ORDER BY movies ASC


-- Αριθμός ταινιών ανά είδος(genre) και ανά χρόνο
SELECT date_part('year', release_date) AS year, genre_name AS genre, COUNT(Metadata.tmdb_id) AS movies FROM Metadata
JOIN Metadata_Genres
ON Metadata.tmdb_id = Metadata_Genres.tmdb_id
JOIN Genres
ON Genres.genre_id = Metadata_Genres.genre_id
GROUP BY year, genre_name
ORDER BY year ASC


-- Μέση βαθμολογία (rating) ανά είδος (ταινίας)
	-- First Solution
	SELECT SUMS.genre, SUMS.ratings_sum / SUMS.movies_sum AS MO_ratings
	FROM (SELECT genre_name AS genre, SUM(rating) AS ratings_sum, COUNT(Ratings.movie_id) AS movies_sum FROM Ratings
			JOIN Links
			ON Links.movie_id = Ratings.movie_id
			JOIN Metadata_Genres
			ON Links.tmdb_id = Metadata_Genres.tmdb_id
			JOIN Genres
			ON Genres.genre_id = Metadata_Genres.genre_id
			GROUP BY genre_name) AS SUMS

	-- Second Solution
	SELECT genre_name AS genre, AVG(rating) AS MO_ratings
	FROM Ratings
		JOIN Links
		ON Links.movie_id = Ratings.movie_id
		JOIN Metadata_Genres
		ON Links.tmdb_id = Metadata_Genres.tmdb_id
		JOIN Genres
		ON Genres.genre_id = Metadata_Genres.genre_id
	GROUP BY genre_name


-- Αριθμός από ratings ανά χρήστη
SELECT user_id, COUNT(rating) AS ratings FROM Ratings
GROUP BY user_id
ORDER BY user_id ASC


-- Μέση βαθμολογία (rating) ανά χρήστη
SELECT user_id, AVG(rating) AS MO_ratings FROM Ratings
GROUP BY user_id
ORDER BY user_id ASC



-- Create View
CREATE VIEW user_ratings_info AS
	SELECT user_id, COUNT(rating) AS ratings_count, AVG(rating) AS ratings_average FROM Ratings
	GROUP BY user_id
	ORDER BY user_id ASC


-- Create Tables to export them in CSV and make the statistics

-- 1st
CREATE TABLE first_bullet_statistics AS 
(SELECT date_part('year', release_date) AS year, COUNT(tmdb_id) AS movies FROM Metadata
	GROUP BY year
	ORDER BY year ASC)

-- 2nd
CREATE TABLE second_bullet_statistics AS 
(SELECT genre_name AS genre, COUNT(Metadata.tmdb_id) AS movies FROM Metadata
	JOIN Metadata_Genres
	ON Metadata.tmdb_id = Metadata_Genres.tmdb_id
	JOIN Genres
	ON Genres.genre_id = Metadata_Genres.genre_id
	GROUP BY genre_name
	ORDER BY movies ASC)

-- 3rd
CREATE TABLE third_bullet_statistics AS 
(SELECT date_part('year', release_date) AS year, genre_name AS genre, COUNT(Metadata.tmdb_id) AS movies FROM Metadata
	JOIN Metadata_Genres
	ON Metadata.tmdb_id = Metadata_Genres.tmdb_id
	JOIN Genres
	ON Genres.genre_id = Metadata_Genres.genre_id
	GROUP BY year, genre_name
	ORDER BY year ASC)

-- 4th
CREATE TABLE fourth_bullet_statistics AS 
(SELECT genre_name AS genre, AVG(rating) AS MO_ratings
	FROM Ratings
		JOIN Links
		ON Links.movie_id = Ratings.movie_id
		JOIN Metadata_Genres
		ON Links.tmdb_id = Metadata_Genres.tmdb_id
		JOIN Genres
		ON Genres.genre_id = Metadata_Genres.genre_id
	GROUP BY genre_name)

-- 5th
CREATE TABLE fifth_bullet_statistics AS 
(SELECT user_id, COUNT(rating) AS ratings FROM Ratings
	GROUP BY user_id
	ORDER BY user_id ASC)

-- 6th
CREATE TABLE sixth_bullet_statistics AS 
(SELECT user_id, AVG(rating) AS MO_ratings FROM Ratings
	GROUP BY user_id
	ORDER BY user_id ASC)
	
-- DROP all tables used for statistics
DROP TABLE first_bullet_statistics
DROP TABLE second_bullet_statistics
DROP TABLE third_bullet_statistics
DROP TABLE fourth_bullet_statistics
DROP TABLE fifth_bullet_statistics
DROP TABLE sixth_bullet_statistics