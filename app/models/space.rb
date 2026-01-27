class Space < ApplicationRecord
  has_many :bookings, dependent: :destroy

  validates :name, presence: true

  scope :active, -> { where(active: true) }
end
