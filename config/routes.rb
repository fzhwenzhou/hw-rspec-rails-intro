Rottenpotatoes::Application.routes.draw do
  resources :movies
  get '/search' => 'movies#search_tmdb', as: 'search_tmdb'
  post '/add_movie' => 'movies#add_movie', as: 'add_movie'
  # map '/' to be a redirect to '/movies'
  root to: redirect('/movies')
end
