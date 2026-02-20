require "csv"

namespace :import do
  desc "Import users from CSV file (secrets/users.csv)"
  task users: :environment do
    csv_path = Rails.root.join("users.csv")

    unless File.exist?(csv_path)
      puts "❌ CSV file not found at #{csv_path}"
      exit 1
    end

    puts "📥 Importing users from #{csv_path}..."

    imported_count = 0
    updated_count = 0
    skipped_count = 0
    error_count = 0

    CSV.foreach(csv_path, headers: true, encoding: "UTF-8") do |row|
      email = row["Email"]&.strip&.downcase

      # Skip rows without email
      if email.blank?
        skipped_count += 1
        next
      end

      # Check if user already exists
      existing_user = User.find_by(email_address: email)

      # Build name from available fields
      first_name = row["First Name"]&.strip
      middle_name = row["Middle Name"]&.strip
      last_name = row["Last Name"]&.strip
      nick_name = row["Nick Name"]&.strip

      name = if nick_name.present?
        nick_name
      else
        [ first_name, middle_name, last_name ].compact.join(" ").strip
      end

      # Skip if we don't have a name
      if name.blank?
        name = email.split("@").first
      end

      # Build location from available fields
      location_parts = [
        row["City"]&.strip,
        row["State"]&.strip,
        row["Country"]&.strip
      ].compact
      location = location_parts.join(", ").presence

      # Get category as skills
      skills = row["Category"]&.strip

      # Get notes as bio
      bio = row["Notes"]&.strip

      begin
        if existing_user
          # Update existing user
          existing_user.update!(approved: true) unless existing_user.approved?

          # Create associate membership if they don't have one
          unless existing_user.memberships.exists?
            Membership.create!(
              user: existing_user,
              membership_type: :associate,
              starts_on: Date.current,
              expires_on: nil,
              notes: "Imported from CSV"
            )
          end

          puts "🔄 Updated: #{name} (#{email})"
          updated_count += 1
        else
          # Create new user with random password (they'll need to reset)
          user = User.create!(
            email_address: email,
            password: SecureRandom.hex(32),
            approved: true,
            role: :viewer
          )

          # Create profile
          Profile.create!(
            user: user,
            name: name,
            location: location,
            skills: skills,
            bio: bio,
            visible: true,
            public_gallery: false
          )

          # Create associate membership (no expiration)
          Membership.create!(
            user: user,
            membership_type: :associate,
            starts_on: Date.current,
            expires_on: nil,
            notes: "Imported from CSV"
          )

          puts "✅ Imported: #{name} (#{email})"
          imported_count += 1
        end
      rescue => e
        puts "❌ Error importing #{email}: #{e.message}"
        error_count += 1
      end
    end

    puts "\n📊 Import complete!"
    puts "   ✅ Imported: #{imported_count}"
    puts "   🔄 Updated: #{updated_count}"
    puts "   ⏭️  Skipped: #{skipped_count}"
    puts "   ❌ Errors: #{error_count}"
  end
end
