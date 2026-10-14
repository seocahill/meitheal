class Booking < ApplicationRecord
  belongs_to :space
  belongs_to :user
  belongs_to :approved_by, class_name: "User", optional: true
  has_many :payments, dependent: :nullify

  # Virtual attributes for agreement checkboxes
  attr_accessor :agree_booking_rules, :agree_ethics

  validates :title, presence: true
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validate :ends_after_starts
  validate :no_overlapping_bookings
  validate :agreements_accepted, on: :create
  validate :no_unpaid_bookings_for_user, on: :create

  enum :status, { pending: 0, confirmed: 1, cancelled: 2 }, default: :pending

  scope :confirmed, -> { where(status: :confirmed) }
  scope :upcoming, -> { where("starts_at > ?", Time.current).order(:starts_at) }
  scope :for_date, ->(date) {
    where("starts_at >= ? AND starts_at < ?", date.beginning_of_day, date.end_of_day)
  }
  # Bookings that start on a day in the range; either end may be open.
  scope :starting_within, ->(range) {
    next unless range

    where(starts_at: range.begin&.beginning_of_day..range.end&.end_of_day)
  }
  scope :unpaid, -> { where(paid: false).where.not(status: :cancelled) }
  scope :overdue, -> { where("ends_at < ?", 2.weeks.ago) }

  def payment_overdue?
    confirmed? && !paid? && ends_at < 2.weeks.ago
  end

  # Completed payments from the booker that can settle this booking: not yet used for
  # another booking and not a membership fee.
  def payment_candidates
    Payment.completed
           .where(membership_id: user.memberships.select(:id), booking_id: nil)
           .where(purpose: [ nil, *Payment.purposes.keys - [ "membership" ] ])
  end

  # Settles the booking with a payment already on file. Raises RecordNotFound unless the
  # payment is one of the candidates.
  def attach_payment!(payment)
    transaction do
      payment_candidates.find(payment.id).update!(booking: self)
      update!(paid: true)
    end
  end

  # Successful SumUp transactions that no payment or ticket accounts for, newest first. The
  # bank account is SumUp's, and its transactions do not say who paid, so these are not
  # limited to the booker.
  def sumup_candidates
    SumupTransaction.unmatched.order(occurred_at: :desc)
  end

  # Settles the booking with a SumUp transaction, recording it as the booker's payment.
  # Raises RecordNotFound unless the transaction is one of the candidates.
  def attach_sumup_transaction!(sumup_transaction)
    transaction do
      received = sumup_candidates.find(sumup_transaction.id)
      settle_with_new_payment!(
        amount_cents: received.amount_cents,
        payment_method: :sumup,
        paid_on: received.occurred_at.to_date,
        notes: received.product_summary,
        sumup_transaction_id: received.transaction_id.presence || received.sumup_id
      )
    end
  end

  # Records an offline payment from the booker and settles the booking.
  def record_payment!(amount_euro:, payment_method:, paid_on: Date.current, notes: nil)
    settle_with_new_payment!(amount_euro: amount_euro, payment_method: payment_method, paid_on: paid_on, notes: notes)
  end

  # Corrects a payment recorded in error. The payments stay on file and can be used again.
  def mark_unpaid!
    transaction do
      payments.update_all(booking_id: nil)
      update!(paid: false)
    end
  end

  def editable_by?(user)
    return false unless user
    self.user == user || user.can_edit?
  end

  private

  # The payment sits on the booker's membership, which it does not renew. A booker with no
  # membership gets an associate one.
  def settle_with_new_payment!(**payment_attributes)
    transaction do
      membership = user.memberships.first || user.memberships.create!(membership_type: :associate, starts_on: Date.current)
      payments.create!(
        membership: membership,
        purpose: :booking,
        status: :completed,
        user_email: user.email_address,
        user_name: membership.payer_name,
        description: "Booking: #{title}",
        **payment_attributes
      )
      update!(paid: true)
    end
  end

  def no_overlapping_bookings
    return if starts_at.blank? || ends_at.blank? || space.blank?

    linked_ids = space.linked_space_ids
    return if linked_ids.empty?

    overlapping = Booking.where(space_id: linked_ids)
      .where.not(status: :cancelled)
      .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)
    overlapping = overlapping.where.not(id: id) if persisted?

    if overlapping.exists?
      errors.add(:base, "conflicts with an existing booking on a linked space")
    end
  end

  def ends_after_starts
    return if starts_at.blank? || ends_at.blank?
    if ends_at <= starts_at
      errors.add(:ends_at, "must be after start time")
    end
  end

  def agreements_accepted
    unless agree_booking_rules.to_s == "1"
      errors.add(:agree_booking_rules, "must be accepted")
    end
    unless agree_ethics.to_s == "1"
      errors.add(:agree_ethics, "must be accepted")
    end
  end

  def no_unpaid_bookings_for_user
    if user&.bookings&.confirmed&.unpaid&.overdue&.any?
      errors.add(:base, "You have unpaid bookings. Please settle outstanding payments before making a new booking.")
    end
  end
end
