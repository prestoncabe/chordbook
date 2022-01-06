class Api::AlbumsController < ApiController
  before_action :set_artist, only: :index

  def index
    @albums = @artist.albums.order_by_popular.limit(10)
  end

  def show
    @album = Album.find(params[:id])
  end

  private

  def set_artist
    @artist = Artist.find(params[:artist_id])
  end
end
