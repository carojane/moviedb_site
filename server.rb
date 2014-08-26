require 'sinatra'
require 'pry'
require 'pg'

##################################################################################
###################################   METHODS    #################################
##################################################################################

def db_connection
  begin
    connection = PG.connect(dbname: 'movies')

    yield(connection)

  ensure
    connection.close
  end
end

def actorsdb
  db_connection do |conn|
    actors_names = conn.exec('SELECT name, id FROM actors ORDER BY name;')
  end
end

def actor_info(chosen_actor)
  db_connection do |conn|
    sql = 'SELECT actors.name, actors.id, movies.title, movies.id AS movie_id, cast_members.character FROM actors
    JOIN cast_members ON cast_members.actor_id = actors.id
    JOIN movies ON cast_members.movie_id = movies.id
    WHERE actors.id = $1
    ORDER BY movies.year DESC'

    actors_info = conn.exec(sql, [chosen_actor]).to_a
  end
end

def moviesdb
  db_connection do |conn|
    sql = 'SELECT movies.title, movies.id, movies.year, movies.rating, genres.name AS genre, studios.name AS studio FROM movies
    JOIN studios ON studios.id = movies.studio_id
    JOIN genres ON genres.id = movies.genre_id
    ORDER BY movies.title;'

    movies = conn.exec(sql).to_a
  end
end

def movie_info(chosen_movie)
  db_connection do |conn|
    sql = 'SELECT movies.title, movies.id, movies.year, movies.rating, cast_members.character, actors.name, actors.id AS actor_id, genres.name AS genre, studios.name AS studio FROM movies
    JOIN studios ON studios.id = movies.studio_id
    JOIN genres ON genres.id = movies.genre_id
    JOIN cast_members ON movies.id = cast_members.movie_id
    JOIN actors ON actors.id = cast_members.actor_id
    WHERE movies.id = $1;'

    movies_info = conn.exec(sql, [chosen_movie]).to_a
  end
end

##################################################################################
##################################   LAUNCH   ####################################
##################################################################################


get '/actors' do
  @actors_names = actorsdb

  erb :actors
end

get '/actors/:id' do
  @actor = params[:id]
  @actor_info = actor_info(@actor)
  @actor_name = @actor_info[0]["name"]

  erb :actor_id
end

get '/movies' do
  @moviesdb = moviesdb

  erb :movies
end

get '/movies/:id' do
  @movie = params[:id]
  @movie_info = movie_info(@movie)
  @movie_title = @movie_info[0]["title"]

  erb :movie_id
end
