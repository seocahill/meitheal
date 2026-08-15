class AllowNullSubjectOnCachedEmails < ActiveRecord::Migration[8.1]
  def change
    change_column_null :cached_emails, :subject, true
  end
end
