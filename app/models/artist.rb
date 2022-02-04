class Artist < ApplicationRecord
  include AlphaPaginate
  include Metadata
  include PgSearch::Model

  has_many :albums, dependent: :destroy
  has_many :tracks, dependent: :destroy
  has_many :artist_works, dependent: :destroy
  has_many :songsheets, through: :artist_works, source: :work, source_type: "Songsheet"
  belongs_to :genre, optional: true

  before_validation :associate_genre
  after_commit(on: :create) { LookupMetadata.perform_later(self) }

  multisearchable against: [:name],
    additional_attributes: ->(record) { record.searchable_data }

  def searchable_data
    {
      weight: 0.8,
      data: {
        title: name,
        subtitle: nil,
        thumbnail: thumbnail
      }
    }
  end

  map_metadata(
    strArtistThumb: :thumbnail,
    strStyle: :style,
    strBiographyEN: :biography
  )

  def banner
    %w[strArtistFanart strArtistWideThumb].map { |x| metadata[x] if metadata }.compact.first
  end

  def associate_genre
    return if metadata["strGenre"].blank?
    self.genre = Genre.find_or_create_by!(name: metadata["strGenre"])
  end
end