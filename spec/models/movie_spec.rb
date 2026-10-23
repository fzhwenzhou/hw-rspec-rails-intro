require 'rails_helper'
require 'spec_helper'

describe Movie, type: :model do
  describe 'searching Tmdb by keyword' do
    it 'calls Faraday gem with CS169 domain' do
      expect(Faraday).to receive(:get).and_call_original
      Movie.find_in_tmdb({title: 'Olympics', release_year: '2000', language: 'all'})
    end
    it 'calls Tmdb with valid API key' do
      Movie.find_in_tmdb({title: "hacker", language: "en"}, 'fake-key')
      expect(a_request(:get, /api.themoviedb.org/).
        with(query: hash_including('api_key' => 'fake-key', 'query' => 'hacker', 'language' => 'en'))).
        to have_been_made
    end
    it 'passes the release year when given' do
      Movie.find_in_tmdb({title: 'Olympics', release_year: '2000'})
      expect(a_request(:get, /api.themoviedb.org/).
        with(query: hash_including('year' => '2000'))).to have_been_made
    end
    it 'omits the release year and language when not restricted' do
      Movie.find_in_tmdb({title: 'Olympics', release_year: '', language: 'all'})
      expect(a_request(:get, /api.themoviedb.org/).
        with { |req| !req.uri.query_values.key?('year') && !req.uri.query_values.key?('language') }).
        to have_been_made
    end

    describe 'returned movies' do
      before :each do
        @movies = Movie.find_in_tmdb({title: 'Olympics', release_year: '2000'})
      end
      it 'returns one Movie per search result' do
        expect(@movies.size).to eq(2)
        expect(@movies).to all(be_a(Movie))
      end
      it 'does not save them to the database' do
        expect(@movies).to all(be_new_record)
        expect(Movie.count).to eq(0)
      end
      it 'fills in title, release date and description from TMDb' do
        expect(@movies.first.title).to eq('Sydney 2000 Olympics Opening Ceremony')
        expect(@movies.first.release_date.to_date).to eq(Date.new(2000, 9, 15))
        expect(@movies.first.description).to start_with('Coverage of the glorious')
      end
      it 'rates every movie R' do
        expect(@movies.map(&:rating)).to all(eq('R'))
      end
    end

    it 'returns an empty list when nothing matches' do
      stub_request(:get, /api.themoviedb.org/).
        to_return(status: 200, body: JSON.generate({page: 1, results: [], total_pages: 0, total_results: 0}))
      expect(Movie.find_in_tmdb({title: 'qwertyuiopasdf'})).to eq([])
    end
    it 'returns an empty list when the API key is invalid' do
      stub_request(:get, /api.themoviedb.org/).
        to_return(status: 401, body: JSON.generate({status_code: 7, status_message: 'Invalid API key: You must be granted a valid key.', success: false}))
      expect(Movie.find_in_tmdb({title: 'hacker'}, 'bad-key')).to eq([])
    end
  end
end
