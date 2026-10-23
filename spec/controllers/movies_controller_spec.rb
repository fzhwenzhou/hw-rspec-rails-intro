require 'rails_helper'

describe MoviesController, type: :controller do
  describe 'searching TMDb' do
    before :each do
      @fake_results = [double('movie1'), double('movie2')]
    end
    it 'calls the model method that performs TMDb search' do
      expect(Movie).to receive(:find_in_tmdb).
        with(hash_including(title: 'hardware', release_year: '2000', language: 'en')).
        and_return(@fake_results)
      get :search_tmdb, params: {:title => 'hardware', :release_year => '2000', :language => 'en'}
    end
    describe 'after valid search' do
      before :each do
        allow(Movie).to receive(:find_in_tmdb).and_return(@fake_results)
        get :search_tmdb, params: {:title => 'hardware'}
      end
      it 'selects the Search Results template for rendering' do
        expect(response).to render_template('search_tmdb')
      end
      it 'makes the TMDb search results available to that template' do
        expect(assigns(:movies)).to eq(@fake_results)
      end
    end
    describe 'without a search' do
      it 'shows the search form without calling TMDb or flashing an error' do
        expect(Movie).not_to receive(:find_in_tmdb)
        get :search_tmdb
        expect(response).to render_template('search_tmdb')
        expect(flash.now[:danger]).to be_nil
      end
    end
    describe 'with a blank title' do
      before :each do
        expect(Movie).not_to receive(:find_in_tmdb)
        get :search_tmdb, params: {:title => '', :release_year => '2000'}
      end
      it 'does not call TMDb and flashes an error' do
        expect(flash.now[:danger]).to eq('Please fill in all required fields!')
      end
      it 'still renders the search template' do
        expect(response).to render_template('search_tmdb')
      end
    end
    describe 'with no matching movies' do
      it 'flashes a no-results message' do
        allow(Movie).to receive(:find_in_tmdb).and_return([])
        get :search_tmdb, params: {:title => 'qwertyuiopasdf'}
        expect(flash.now[:info]).to eq('No movies found with given parameters!')
      end
    end
  end

  describe 'adding a movie from TMDb' do
    let(:movie_params) do
      {:title => 'Manhunter', :rating => 'R', :release_date => '1986-08-15',
       :description => 'A former FBI profiler hunts a serial killer.'}
    end
    it 'saves the movie to the database' do
      expect { post :add_movie, params: {:movie => movie_params} }.
        to change(Movie, :count).by(1)
      expect(Movie.last.title).to eq('Manhunter')
    end
    it 'redirects to the search page with a success message' do
      post :add_movie, params: {:movie => movie_params}
      expect(response).to redirect_to(search_tmdb_path)
      expect(flash[:success]).to eq('Manhunter was successfully added to RottenPotatoes.')
    end
  end
end
