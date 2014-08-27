require 'sinatra'
require 'sinatra/reloader'
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

def get_data(query)
  db_connection do |conn|
    conn.exec(query)
  end
end

def get_data_with_query(query, id)
  db_connection do |conn|
    conn.exec(query, [id])
  end
end

def sort_by_params(query, sort)
  case sort
  when 'rating'
    query += ' ORDER BY movies.rating DESC, movies.title LIMIT 20'
  when 'year'
    query += ' ORDER BY movies.year DESC, movies.title LIMIT 20'
  when
    query += ' ORDER BY movies.title LIMIT 20'
  end
  query
end

def offset(page, data)
  page ||=1
  offset = ((page * 20) - 20).to_s
  if offset.to_i > 0
    data += ' OFFSET ' + offset
  else
    data
  end
  data
end


##################################################################################
##################################   LAUNCH   ####################################
##################################################################################

get '/' do
  redirect '/movies'
end

get '/actors' do
  page = params[:page].to_i
  query = 'SELECT actors.id, actors.name FROM actors ORDER BY actors.name LIMIT 20'

  @current_page = page ||= 1
    if @current_page == 1
      @previous_page = 1
    else
       @previous_page = @current_page - 1
    end
  @next_page = @current_page + 1

  @actors_done = offset(page, query)
  @actors_names = get_data(@actors_done)

  erb :actors
end

get '/actors/:id' do
  id = params[:id]
  query = 'SELECT actors.name, actors.id, movies.title,
    movies.id AS movie_id, cast_members.character FROM actors
    JOIN cast_members ON cast_members.actor_id = actors.id
    JOIN movies ON cast_members.movie_id = movies.id
    WHERE actors.id = $1
    ORDER BY movies.year DESC'

  @actor_info = get_data_with_query(query,id)
  @actor_name = @actor_info[0]["name"]

  erb :actor_id
end

get '/movies' do
  page = params[:page].to_i
  query = 'SELECT movies.title, movies.id, movies.year, movies.rating,
    genres.name AS genre, studios.name AS studio FROM movies
    LEFT OUTER JOIN studios ON studios.id = movies.studio_id
    LEFT OUTER JOIN genres ON genres.id = movies.genre_id'

#### so clicking on previous page on page 1 doesn't go backwards
  @current_page = page ||= 1
    if @current_page == 1
      @previous_page = 1
    else
       @previous_page = @current_page - 1
    end
  @next_page = @current_page + 1

#### adds sort to query
  sorted_movies = sort_by_params(query, params[:order])
#### adds offset to query
  movies_done = offset(page, sorted_movies)

#### fetches data from SQL
  @moviesdb = get_data(movies_done)
  erb :movies
end

#### individual movie page with title, year, rating, cast, and studio

get '/movies/:id' do
  id = params[:id]
  query = 'SELECT movies.title, movies.id, movies.year, movies.rating, movies.synopsis,
    cast_members.character, actors.name, actors.id AS actor_id,
    genres.name AS genre, studios.name AS studio FROM movies
    LEFT OUTER JOIN studios ON studios.id = movies.studio_id
    LEFT OUTER JOIN genres ON genres.id = movies.genre_id
    JOIN cast_members ON movies.id = cast_members.movie_id
    JOIN actors ON actors.id = cast_members.actor_id
    WHERE movies.id = $1'

  @movie_info = get_data_with_query(query,id)
  @movie_title = @movie_info[0]["title"]

  erb :movie_id
end








