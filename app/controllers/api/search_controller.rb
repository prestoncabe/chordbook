class Api::SearchController < ApiController
  skip_before_action :authenticate!

  def index
    @results = Search.new(query: params[:q], load: false, models: models, page: params[:page], per_page: 25).results
    set_pagination_header @results
    fresh_when @results
  end

  private

  def models
    params[:type].blank? ?
      Search::MODELS :
      Search::MODELS & params[:type].split(",").map { |type| type.singularize.classify.constantize }
  end
end
