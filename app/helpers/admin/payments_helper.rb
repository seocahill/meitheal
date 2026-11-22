module Admin::PaymentsHelper
  # Successful SumUp payments from the last 60 days that no payment or ticket
  # here records, newest first, so owners notice money taken but not booked.
  # Nil when the f216 flag is off for the current user.
  def unrecorded_sumup_transactions
    return @unrecorded_sumup_transactions if defined?(@unrecorded_sumup_transactions)

    @unrecorded_sumup_transactions =
      if Flipper.enabled?(:f216_unrecorded_sumup_payments, Current.user)
        SumupTransaction.unmatched.recent.order(occurred_at: :desc)
      end
  end
end
