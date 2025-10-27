class Blob < ApplicationRecord
  validates :id, presence: true, uniqueness: true
  validates :size, presence: true, numericality: { greater_than: 0 }
  validates :created_at, presence: true

  # Virtual attribute for Base64 data (not stored in database)
  attr_accessor :data

  before_validation :set_created_at, on: :create

  def self.find_by_id!(blob_id)
    find_by!(id: blob_id)
  end

  def data_size
    size
  end

  private

  def set_created_at
    self.created_at ||= Time.current
  end
end
