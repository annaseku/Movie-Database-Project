-- __/\\\\\\\\\\\__/\\\\\_____/\\\__/\\\\\\\\\\\\\\\____/\\\\\_________/\\\\\\\\\_________/\\\\\\\________/\\\\\\\________/\\\\\\\________/\\\\\\\\\\________________/\\\\\\\\\_______/\\\\\\\\\_____        
--  _\/////\\\///__\/\\\\\\___\/\\\_\/\\\///////////___/\\\///\\\_____/\\\///////\\\_____/\\\/////\\\____/\\\/////\\\____/\\\/////\\\____/\\\///////\\\_____________/\\\\\\\\\\\\\___/\\\///////\\\___       
--   _____\/\\\_____\/\\\/\\\__\/\\\_\/\\\____________/\\\/__\///\\\__\///______\//\\\___/\\\____\//\\\__/\\\____\//\\\__/\\\____\//\\\__\///______/\\\_____________/\\\/////////\\\_\///______\//\\\__      
--    _____\/\\\_____\/\\\//\\\_\/\\\_\/\\\\\\\\\\\___/\\\______\//\\\___________/\\\/___\/\\\_____\/\\\_\/\\\_____\/\\\_\/\\\_____\/\\\_________/\\\//_____________\/\\\_______\/\\\___________/\\\/___     
--     _____\/\\\_____\/\\\\//\\\\/\\\_\/\\\///////___\/\\\_______\/\\\________/\\\//_____\/\\\_____\/\\\_\/\\\_____\/\\\_\/\\\_____\/\\\________\////\\\____________\/\\\\\\\\\\\\\\\________/\\\//_____    
--      _____\/\\\_____\/\\\_\//\\\/\\\_\/\\\__________\//\\\______/\\\______/\\\//________\/\\\_____\/\\\_\/\\\_____\/\\\_\/\\\_____\/\\\___________\//\\\___________\/\\\/////////\\\_____/\\\//________   
--       _____\/\\\_____\/\\\__\//\\\\\\_\/\\\___________\///\\\__/\\\______/\\\/___________\//\\\____/\\\__\//\\\____/\\\__\//\\\____/\\\___/\\\______/\\\____________\/\\\_______\/\\\___/\\\/___________  
--        __/\\\\\\\\\\\_\/\\\___\//\\\\\_\/\\\_____________\///\\\\\/______/\\\\\\\\\\\\\\\__\///\\\\\\\/____\///\\\\\\\/____\///\\\\\\\/___\///\\\\\\\\\/_____________\/\\\_______\/\\\__/\\\\\\\\\\\\\\\_ 
--         _\///////////__\///_____\/////__\///________________\/////_______\///////////////_____\///////________\///////________\///////_______\/////////_______________\///________\///__\///////////////__

-- Your Name: Anna Sekulic
-- Your Student Number: 1609641
-- By submitting, you declare that this work was completed entirely by yourself.

-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q1

SELECT imdb_movie.id, imdb_movie.title
FROM imdb_movie
WHERE imdb_movie.id
NOT IN (SELECT DISTINCT imdb_movie_id
		FROM metacritic_review);

-- END Q1
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q2

SELECT netflix_rating.movie_id as NetflixMovieID, 
		netflix_movie.title as MovieTitle, 
		netflix_rating.`timestamp` as TimeOfMostRecentRating
FROM netflix_rating 
INNER JOIN netflix_movie ON netflix_rating.movie_id = netflix_movie.id
ORDER BY netflix_rating.`timestamp` DESC
LIMIT 1;

-- END Q2
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q3

SELECT metacritic_review.imdb_movie_id as IMDBMovieID, COUNT(netflix_rating.id) as NetflixRatingCount
FROM metacritic_review 
INNER JOIN imdb_to_netflix ON metacritic_review.imdb_movie_id = imdb_to_netflix.imdb_movie_id
INNER JOIN netflix_rating ON netflix_rating.movie_id = imdb_to_netflix.netflix_movie_id
WHERE metacritic_review.`source` = 'The Washington Post'
GROUP BY metacritic_review.imdb_movie_id
HAVING COUNT(DISTINCT netflix_rating.id) >= 5;

-- END Q3
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q4          

SELECT genre, TomatometerAvgScore
FROM              
	(SELECT imdb_movie_genre.genre_title as genre, ROUND(AVG(TomatometerScore), 1) AS TomatometerAvgScore, RANK() OVER(ORDER BY ROUND(AVG(TomatometerScore), 1) DESC) AS highest_tomato_rank
	FROM imdb_movie_genre 
	INNER JOIN (SELECT imdb_to_rottentomatoes.imdb_movie_id, AVG(critic_score) AS TomatometerScore
				FROM rottentomatoes_movie 
                INNER JOIN imdb_to_rottentomatoes on imdb_to_rottentomatoes.rt_movie_id = rottentomatoes_movie.id
				GROUP BY imdb_to_rottentomatoes.imdb_movie_id) 
	AS ImdbMovieTomatometerAvgScore 
    ON imdb_movie_genre.movie_id = ImdbMovieTomatometerAvgScore.imdb_movie_id
	GROUP BY imdb_movie_genre.genre_title)
AS Genres_Rankedby_Tomatoes
WHERE highest_tomato_rank = 1;

-- END Q4
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q5

SELECT metacritic_review.score AS Score, metacritic_review.`source` AS `Source`, FilmsWithSpecialActors.title AS IMDBTitle
FROM metacritic_review 
RIGHT JOIN 
	(SELECT DISTINCT id, title 
	FROM imdb_movie
	WHERE id IN 
		(SELECT movie_id
		FROM imdb_acted_in
		WHERE person_id IN
			(SELECT id
			FROM imdb_person
			WHERE (LENGTH(`name`) - LENGTH(REPLACE(`name`, ' ', '')) + 1) > 2))) 
AS FilmsWithSpecialActors 
ON metacritic_review.imdb_movie_id = FilmsWithSpecialActors.id;

-- END Q5
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q6

SELECT Year_Rankings.`Year`, Year_Rankings.MovieCount
FROM 
	(SELECT DISTINCT imdb_movie.`year` AS `Year`, COUNT(DISTINCT imdb_movie.id) AS MovieCount, RANK() OVER(ORDER BY COUNT(DISTINCT imdb_movie.id) DESC) AS Highest_Num_Movies_Rank
	FROM imdb_movie
	WHERE imdb_movie.id IN 
		(SELECT imdb_to_movielens.imdb_movie_id
		FROM movielens_tag 
		INNER JOIN imdb_to_movielens ON movielens_tag.movie_id = imdb_to_movielens.movielens_movie_id
		WHERE movielens_tag.tag = 'action_thriller')
	AND imdb_movie.classification = 'pg'
	GROUP BY imdb_movie.`year`) AS Year_Rankings
WHERE Highest_Num_Movies_Rank = 1;

-- END Q6
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q7
    
SELECT (SELECT COUNT(imdb_nonetflix.id)
		FROM imdb_movie AS imdb_nonetflix
		WHERE imdb_nonetflix.id NOT IN 
			(SELECT imdb_movie_id
			FROM imdb_to_netflix)) 
AS X,
	   (SELECT COUNT(imdb_nomovielens.id)
		FROM imdb_movie AS imdb_nomovielens
		WHERE imdb_nomovielens.id NOT IN 
			(SELECT imdb_movie_id
			FROM imdb_to_movielens)) 
AS Y;
    
-- END Q7
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q8

SELECT metacritic_review.`source` AS globalReviewSource, imdb_movie.`language`, 
		COUNT(metacritic_review.imdb_movie_id) AS countReviewsForLanguage, 
        ROUND(AVG(metacritic_review.score), 1) AS avgScoreForLanguage, 
        ROUND(STDDEV(metacritic_review.score), 1) AS popStdDevScoreForLanguage
FROM metacritic_review
INNER JOIN imdb_movie ON metacritic_review.imdb_movie_id = imdb_movie.id
WHERE metacritic_review.`source` IN
	(SELECT metacritic_review.`source`
	FROM metacritic_review
	INNER JOIN imdb_movie ON metacritic_review.imdb_movie_id = imdb_movie.id
	GROUP BY metacritic_review.`source`
	HAVING COUNT(DISTINCT `language`) =
		(SELECT COUNT(DISTINCT `language`)
		FROM imdb_movie))
GROUP BY imdb_movie.`language`, metacritic_review.`source`
ORDER BY metacritic_review.`source`, imdb_movie.`language`;


-- END Q8
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q9

SELECT imdb_person.`name` AS ActorName, NumberOfUniqueGenres, TotalNumberOfTags
FROM 
	 -- gives all multitalented actors and their number of distinct genres; checked
	(SELECT imdb_acted_in.person_id AS person_id, COUNT(DISTINCT imdb_movie_genre.genre_title) AS NumberOfUniqueGenres
	 FROM imdb_acted_in
	 INNER JOIN imdb_movie_genre ON imdb_acted_in.movie_id = imdb_movie_genre.movie_id
	 GROUP BY imdb_acted_in.person_id
	 HAVING COUNT(DISTINCT imdb_movie_genre.genre_title) >= 5) AS Person_Distinct_Genres
NATURAL JOIN
	-- gives all actors and their total number of tags
	(SELECT imdb_acted_in.person_id AS person_id, SUM(IFNULL(MoviesNumTags, 0)) AS TotalNumberOfTags
	 FROM 
		 -- gets all movies that have been tagged and the number of times they've been tagged
		 (SELECT imdb_to_movielens.imdb_movie_id AS imdb_movie_id, COUNT(movielens_tag.id) AS MoviesNumTags
		 FROM movielens_tag 
         LEFT JOIN imdb_to_movielens ON movielens_tag.movie_id = imdb_to_movielens.movielens_movie_id
		 GROUP BY imdb_to_movielens.imdb_movie_id) AS movie_numtags
	 -- joins back with actors, adding a new column 'MoviesNumTags'
	 RIGHT JOIN imdb_acted_in ON movie_numtags.imdb_movie_id = imdb_acted_in.movie_id 
	 GROUP BY imdb_acted_in.person_id) AS Person_Num_Tags
INNER JOIN imdb_person ON imdb_person.id = Person_Distinct_Genres.person_id;

-- END Q9
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q10

SELECT All_Data.netflix_movie_id AS NetflixMovieID, All_Data.metacritic_av_rating AS RoundedAvgMetacriticScore, All_Data.netflix_av_rating AS RoundedAvgNetflixScoreAsPercent
FROM 
	(SELECT Netflix_Data.netflix_movie_id, Metacritic_Data.metacritic_av_rating, Netflix_Data.netflix_av_rating, RANK() OVER(ORDER BY Netflix_Data.netflix_av_rating DESC) AS netflix_rank
	FROM 
		-- netflix ids, netflix ratings of all 2021/2022 netflix movies reviewed on netflix
		(SELECT netflix_rating.movie_id AS netflix_movie_id, ROUND(100*(AVG(netflix_rating.rating)/5), 1) AS netflix_av_rating
		FROM (netflix_rating INNER JOIN netflix_movie ON netflix_rating.movie_id = netflix_movie.id)
		WHERE netflix_movie.`year` = 2021 OR netflix_movie.`year` = 2022
		GROUP BY netflix_rating.movie_id)
	AS Netflix_Data
	INNER JOIN
		-- netflix ids, metacritic ratings of all netflix movies reviewed on metacritic
		(SELECT imdb_to_netflix.netflix_movie_id AS netflix_movie_id, metacritic_av_rating
		FROM 
			(SELECT imdb_movie_id, ROUND(AVG(score), 1) AS metacritic_av_rating
			FROM metacritic_review
			GROUP BY imdb_movie_id) 
			AS Metacritic_Averages
			INNER JOIN imdb_to_netflix ON imdb_to_netflix.imdb_movie_id = Metacritic_Averages.imdb_movie_id)
	AS Metacritic_Data
	ON Netflix_Data.netflix_movie_id = Metacritic_Data.netflix_movie_id
	WHERE ABS(Netflix_Data.netflix_av_rating - Metacritic_Data.metacritic_av_rating) <= 15)
AS All_Data
WHERE All_Data.netflix_rank <= 3;

-- END Q10
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- END OF ASSIGNMENT Do not write below this line