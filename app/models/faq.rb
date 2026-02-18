class Faq < ApplicationRecord
  has_rich_text :answer

  validates :question, presence: true
  validates :order, numericality: { only_integer: true }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :by_order, -> { order(Arel.sql("COALESCE(\"order\", 999), id")) }

  def self.next_order
    maximum(:order).to_i + 10
  end
end
