class BlobStorage < ApplicationRecord
  validates :id, presence: true
  validates :data, presence: true
end
