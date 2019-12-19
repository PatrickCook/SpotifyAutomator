class PlayedTrack < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :genres

  serialize :old_genres, Array
end
