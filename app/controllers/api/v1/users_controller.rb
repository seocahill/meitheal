module Api
  module V1
    class UsersController < ResourceController
      # Deliberately excludes :role (no privilege escalation via the API). The
      # password digest is stripped by Api::RecordSerializer for every resource.
      permits :email_address, :approved, :password, :password_confirmation
    end
  end
end
