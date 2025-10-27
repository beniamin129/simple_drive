class AuthenticationToken < ApplicationRecord
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :valid, -> { where("expires_at > ?", Time.current) }

  def self.generate
    token = SecureRandom.hex(32)
    expires_at = 24.hours.from_now
    create!(token: token, expires_at: expires_at)
  end

  def expired?
    expires_at < Time.current
  end

  def still_valid?
    !expired?
  end
end
