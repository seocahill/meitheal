class Space < ApplicationRecord
  belongs_to :component_of, class_name: "Space", optional: true
  has_many :component_spaces, class_name: "Space", foreign_key: :component_of_id
  has_many :bookings, dependent: :destroy

  validates :name, presence: true

  scope :active, -> { where(active: true) }

  # IDs of spaces that conflict with this one for booking overlap purposes.
  # Component space (e.g. Back Room) conflicts with its parent (Whole Building).
  # Composite space (e.g. Whole Building) conflicts with all its components.
  def linked_space_ids
    if component_of_id.present?
      [ component_of_id ]
    else
      component_spaces.pluck(:id)
    end
  end
end
