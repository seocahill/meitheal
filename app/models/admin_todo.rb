class AdminTodo < ApplicationRecord
  # Polymorphic source for linking to emails, etc.
  belongs_to :source, polymorphic: true, optional: true

  enum :priority, { low: 0, normal: 1, high: 2, urgent: 3 }, default: :normal

  validates :title, presence: true

  # Scopes
  scope :pending, -> { where(completed: false) }
  scope :completed, -> { where(completed: true) }
  scope :due_soon, -> { pending.where(due_date: Date.current..3.days.from_now.to_date) }
  scope :overdue, -> { pending.where(due_date: ...Date.current) }
  scope :by_position, -> { order(Arel.sql("position IS NULL, position ASC")) }
  scope :by_due_date, -> { order(Arel.sql("due_date IS NULL, due_date ASC")) }
  scope :by_priority, -> { order(priority: :desc) }

  # Default ordering for todo list
  scope :default_order, -> { by_priority.by_due_date.by_position }

  def overdue?
    due_date.present? && due_date < Date.current && !completed?
  end

  def due_soon?
    due_date.present? && due_date <= 3.days.from_now.to_date && due_date >= Date.current && !completed?
  end

  def toggle_completed!
    update!(completed: !completed)
  end
end
