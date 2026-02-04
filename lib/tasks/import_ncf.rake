namespace :import do
  desc "Import content from old NCF Middleman site"
  task ncf: :environment do
    require 'yaml'

    # Base URL for referencing old site images
    OLD_SITE_IMAGE_BASE = "https://thencf.art/images"
    NCF_SOURCE_PATH = Rails.root.join("..", "ncf", "source")

    # Helper to parse markdown files with frontmatter
    def parse_markdown_file(file_path)
      content = File.read(file_path)

      # Split frontmatter and body
      if content =~ /\A---\s*\n(.*?)\n---\s*\n(.*)\z/m
        frontmatter = YAML.safe_load($1, permitted_classes: [Date, Time])
        body = $2
        { frontmatter: frontmatter, body: body }
      else
        { frontmatter: {}, body: content }
      end
    end

    # Find or create admin user for imported content
    admin_user = User.find_by(role: :owner) || User.first
    unless admin_user
      puts "No admin user found. Please create a user first."
      exit 1
    end

    puts "Importing as user: #{admin_user.email_address}"

    # Import Events
    puts "\n=== Importing Events ==="
    events_path = NCF_SOURCE_PATH.join("events")
    if Dir.exist?(events_path)
      Dir.glob(events_path.join("*.markdown")).each do |file|
        data = parse_markdown_file(file)
        fm = data[:frontmatter]

        next if fm['title'].blank?

        # Generate slug from filename
        slug = File.basename(file, ".html.markdown").sub(/^\d{4}-\d{2}-\d{2}-/, '')

        event = Event.find_or_initialize_by(title: fm['title'])
        event.assign_attributes(
          user: admin_user,
          description: data[:body],
          starts_at: fm['date'] || Date.today,
          published: true
        )

        if event.save
          puts "✓ Imported event: #{fm['title']}"
        else
          puts "✗ Failed to import event: #{fm['title']} - #{event.errors.full_messages.join(', ')}"
        end
      end
    else
      puts "Events directory not found at #{events_path}"
    end

    # Import News/Blog Posts
    puts "\n=== Importing News/Blog Posts ==="
    news_path = NCF_SOURCE_PATH.join("news")
    if Dir.exist?(news_path)
      Dir.glob(news_path.join("*.markdown")).each do |file|
        data = parse_markdown_file(file)
        fm = data[:frontmatter]

        next if fm['title'].blank?

        # Generate slug from title
        base_slug = fm['title'].parameterize

        post = Post.find_or_initialize_by(slug: base_slug)
        post.assign_attributes(
          user: admin_user,
          title: fm['title'],
          body: data[:body],
          excerpt: data[:body].gsub(/<[^>]*>/, '').truncate(200),
          published_at: fm['date'] || Date.today
        )

        if post.save
          puts "✓ Imported post: #{fm['title']}"
        else
          puts "✗ Failed to import post: #{fm['title']} - #{post.errors.full_messages.join(', ')}"
        end
      end
    else
      puts "News directory not found at #{news_path}"
    end

    # Import FAQs
    puts "\n=== Importing FAQs ==="
    faq_path = NCF_SOURCE_PATH.join("faq")
    if Dir.exist?(faq_path)
      Dir.glob(faq_path.join("*.markdown")).each do |file|
        data = parse_markdown_file(file)
        fm = data[:frontmatter]

        next if fm['title'].blank?

        faq = Faq.find_or_initialize_by(question: fm['title'])
        faq.assign_attributes(
          answer: data[:body],
          order: fm['order'] || 999,
          active: true
        )

        if faq.save
          puts "✓ Imported FAQ: #{fm['title']}"
        else
          puts "✗ Failed to import FAQ: #{fm['title']} - #{faq.errors.full_messages.join(', ')}"
        end
      end
    else
      puts "FAQ directory not found at #{faq_path}"
    end

    # Import Gallery Data
    puts "\n=== Importing Gallery Data ==="
    gallery_path = NCF_SOURCE_PATH.join("..", "data", "gallery.yml")
    if File.exist?(gallery_path)
      gallery_data = YAML.load_file(gallery_path)

      gallery_data['members']&.each do |member|
        # Find or create user/profile for gallery member
        # This is a simplified version - you may want to adjust based on your needs
        email = "#{member['name'].parameterize}@imported.example"
        user = User.find_or_initialize_by(email_address: email)

        if user.new_record?
          user.password = SecureRandom.hex(16)
          user.role = :viewer
          user.save!
        end

        profile = Profile.find_or_initialize_by(user: user)
        profile.assign_attributes(
          name: member['name'],
          bio: member['alt'],
          website: member['link'],
          visible: true
        )

        if profile.save
          puts "✓ Imported gallery member: #{member['name']}"
        else
          puts "✗ Failed to import gallery member: #{member['name']} - #{profile.errors.full_messages.join(', ')}"
        end
      end
    else
      puts "Gallery data file not found at #{gallery_path}"
    end

    puts "\n=== Import Complete ==="
    puts "Events: #{Event.count}"
    puts "Posts: #{Post.count}"
    puts "FAQs: #{Faq.count}"
    puts "Profiles: #{Profile.count}"
    puts "\nNote: Images are still referenced from the old site."
    puts "Run 'rake import:ncf_images' (TODO) to download and attach images with Active Storage."
  end
end
