# Registers the flag so it appears, switched off, in /flipper.
class AddF216UnrecordedSumupPaymentsFlag < ActiveRecord::Migration[8.1]
  def up
    Flipper.add(:f216_unrecorded_sumup_payments)
  end

  def down
    Flipper.remove(:f216_unrecorded_sumup_payments)
  end
end
