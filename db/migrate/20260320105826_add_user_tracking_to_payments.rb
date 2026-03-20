class AddUserTrackingToPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :payments, :user_email, :string
    add_column :payments, :user_name, :string
    add_column :payments, :description, :text

    # Backfill existing records
    reversible do |dir|
      dir.up do
        Payment.reset_column_information
        Payment.find_each do |payment|
          next unless payment.membership&.user

          user = payment.membership.user
          # Extract description from notes, removing status prefixes
          desc = payment.notes.to_s.gsub(/^(Pending|Completed) - /, '')
          desc = 'Payment' if desc.blank?

          payment.update_columns(
            user_email: user.email_address,
            user_name: user.name,
            description: desc
          )
        end
      end
    end

    # Add constraints after backfill
    change_column_null :payments, :user_email, false
    change_column_null :payments, :user_name, false
    change_column_null :payments, :description, false

    add_index :payments, :user_email
  end
end
