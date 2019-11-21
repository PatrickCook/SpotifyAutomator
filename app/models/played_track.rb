class PlayedTrack < ApplicationRecord
  belongs_to :user
  serialize :genres, Array
end
