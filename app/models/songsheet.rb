class Songsheet < ApplicationRecord
  include AlphaPaginate
  include Metadata
  include PgSearch::Model

  belongs_to :track, optional: true
  has_many :artist_works, as: :work
  has_many :artists, through: :artist_works

  scope :order_by_popular, -> {
    includes(:track).order("tracks.listeners DESC NULLS LAST").order_by_recent
  }
  scope :order_by_recent, -> { order(created_at: :desc) }
  scope :order_by_todo, -> { order(Arel.sql("track_id NULLS FIRST, updated_at ASC")) }

  validates :title, presence: true
  validates :format, presence: true

  after_initialize :set_defaults
  before_save :associate_metadata
  after_save :mark_track

  multisearchable additional_attributes: ->(record) { record.searchable_data }

  def searchable_text
    [
      title,
      artists.map(&:name),
      track&.album&.title
    ].flatten.compact.join(" ")
  end

  def searchable_data
    {
      weight: 1.0,
      data: {
        title: title,
        subtitle: metadata["artist"] && "by #{Array(metadata["artist"]).to_sentence}",
        thumbnail: track&.album&.thumbnail
      }
    }
  end

  private

  def set_defaults
    self.format ||= "ChordPro"
  end

  def associate_metadata
    artist_names = Array(metadata["artist"]).map { |a| a.split(/\s*,\s*/) }.flatten
    self.artists = artist_names.map { |name| Artist.lookup(name) || Artist.new(name: name.strip) }
    self.track = Track.where(artist_id: artist_ids.compact).lookup(title)
  end

  def mark_track
    track&.has_songsheet!
  end
end
