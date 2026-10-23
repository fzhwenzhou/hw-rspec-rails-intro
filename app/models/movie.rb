class Movie < ActiveRecord::Base
  def self.all_ratings
    %w[G PG PG-13 R]
  end

  def self.with_ratings(ratings, sort_by)
    if ratings.nil?
      all.order sort_by
    else
      where(rating: ratings.map(&:upcase)).order sort_by
    end
  end

  TMDB_SEARCH_URL = 'https://api.themoviedb.org/3/search/movie'.freeze

  # search_terms: { title:, release_year:, language: } as submitted by the search form.
  # Returns unsaved Movie objects; TMDb search results carry no MPAA rating, so use 'R'.
  def self.find_in_tmdb(search_terms, api_key = ENV.fetch('TMDB_API_KEY', ''))
    query = { api_key: api_key, query: search_terms[:title] }
    query[:year] = search_terms[:release_year] if search_terms[:release_year].present?
    language = search_terms[:language]
    query[:language] = language if language.present? && language != 'all'

    response = Faraday.get(TMDB_SEARCH_URL, query)
    results = JSON.parse(response.body)['results'] || []
    results.map do |movie|
      Movie.new(title: movie['title'], rating: 'R',
                release_date: movie['release_date'], description: movie['overview'])
    end
  end
end
