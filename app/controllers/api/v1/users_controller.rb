module Api
  module V1
    class UsersController < ResourceController
      # Deliberately excludes :role (no privilege escalation via the API) and
      # never exposes the password digest.
      permits :email_address, :approved, :password, :password_confirmation

      private

      def serialize(record)
        super.except("password_digest")
      end
    end
  end
end
