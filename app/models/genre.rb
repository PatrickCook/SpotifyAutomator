class Genre < ApplicationRecord
  has_and_belongs_to_many :played_tracks
end