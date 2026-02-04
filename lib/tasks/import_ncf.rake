namespace :import do
  desc "Import content from old NCF Middleman site"
  task ncf: :environment do
    require 'yaml'
    require 'redcarpet'

    # Base URL for referencing old site images
    OLD_SITE_IMAGE_BASE = "https://thencf.art/images"
    NCF_SOURCE_PATH = Rails.root.join("..", "ncf", "source")

    # Custom renderer that prefixes image URLs with old site base
    class NCFRenderer < Redcarpet::Render::HTML
      def initialize(old_site_base)
        @old_site_base = old_site_base
        super(no_styles: true, safe_links_only: true)
      end

      def image(link, title, alt_text)
        # Convert relative image paths to absolute URLs
        unless link.start_with?('http://', 'https://', '//')
          # Remove leading slash and /images/ if present
          clean_link = link.gsub(/^\//, '').gsub(/^images\//, '')
          link = "#{@old_site_base}/#{clean_link}"
        end

        title_attr = title.present? ? %( title="#{title}") : ""
        %(<img src="#{link}" alt="#{alt_text}"#{title_attr}>)
      end

      def link(link, title, content)
        # Check if the link is to an image file
        if link =~ /\.(jpg|jpeg|png|gif|webp)$/i
          # Convert link to image tag
          unless link.start_with?('http://', 'https://', '//')
            # Remove leading slash and /images/ if present
            clean_link = link.gsub(/^\//, '').gsub(/^images\//, '')
            link = "#{@old_site_base}/#{clean_link}"
          end
          %(<img src="#{link}" alt="#{content}">)
        else
          # Regular link
          title_attr = title.present? ? %( title="#{title}") : ""
          %(<a href="#{link}"#{title_attr}>#{content}</a>)
        end
      end
    end

    # Initialize markdown renderer with custom image handler
    markdown_renderer = NCFRenderer.new(OLD_SITE_IMAGE_BASE)
    markdown = Redcarpet::Markdown.new(
      markdown_renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      space_after_headers: true
    )

    # Helper to convert markdown to HTML
    def markdown_to_html(text, markdown)
      return "" if text.blank?
      markdown.render(text)
    end

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
          description: markdown_to_html(data[:body], markdown),
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
        html_body = markdown_to_html(data[:body], markdown)
        post.assign_attributes(
          user: admin_user,
          title: fm['title'],
          body: html_body,
          excerpt: html_body.gsub(/<[^>]*>/, '').truncate(200),
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
          answer: markdown_to_html(data[:body], markdown),
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
    puts "Run 'rake import:ncf_images' to download and attach images with Active Storage."
  end

  desc "Import images from old NCF site into Active Storage"
  task ncf_images: :environment do
    require 'yaml'
    require 'open-uri'

    NCF_SOURCE_PATH = Rails.root.join("..", "ncf", "source")
    OLD_SITE_URL = "https://thencf.art"

    # Determine if we're in development and can access local files
    use_local_files = Rails.env.development? && Dir.exist?(NCF_SOURCE_PATH.join("images"))

    puts "=== Importing Images ==="
    puts "Mode: #{use_local_files ? 'Local files' : 'Remote URLs'}"

    # Helper to attach image from file or URL
    def attach_image_from_source(record, attachment_name, image_path, use_local:, ncf_source_path:, old_site_url:)
      return if image_path.blank?

      # Normalize image path (remove leading slash, /images/ prefix, etc)
      clean_path = image_path.to_s.gsub(/^\//, '').gsub(/^images\//, '')

      if use_local
        # Try to find the image locally
        local_path = ncf_source_path.join("images", clean_path)
        unless File.exist?(local_path)
          puts "  ✗ Local file not found: #{local_path}"
          return false
        end

        begin
          record.public_send(attachment_name).attach(
            io: File.open(local_path),
            filename: File.basename(clean_path),
            content_type: content_type_for(clean_path)
          )
          puts "  ✓ Attached local image: #{clean_path}"
          return true
        rescue => e
          puts "  ✗ Failed to attach local image #{clean_path}: #{e.message}"
          return false
        end
      else
        # Fetch from remote URL
        remote_url = "#{old_site_url}/images/#{clean_path}"
        begin
          URI.open(remote_url) do |image|
            record.public_send(attachment_name).attach(
              io: image,
              filename: File.basename(clean_path),
              content_type: content_type_for(clean_path)
            )
          end
          puts "  ✓ Attached remote image: #{remote_url}"
          return true
        rescue => e
          puts "  ✗ Failed to fetch remote image #{remote_url}: #{e.message}"
          return false
        end
      end
    end

    def content_type_for(filename)
      ext = File.extname(filename).downcase
      case ext
      when '.jpg', '.jpeg' then 'image/jpeg'
      when '.png' then 'image/png'
      when '.gif' then 'image/gif'
      when '.webp' then 'image/webp'
      else 'application/octet-stream'
      end
    end

    # Helper to parse markdown files with frontmatter
    def parse_markdown_file(file_path)
      content = File.read(file_path)
      if content =~ /\A---\s*\n(.*?)\n---\s*\n(.*)\z/m
        frontmatter = YAML.safe_load($1, permitted_classes: [Date, Time])
        body = $2
        { frontmatter: frontmatter, body: body }
      else
        { frontmatter: {}, body: content }
      end
    end

    # Import Event Images
    puts "\n=== Importing Event Images ==="
    events_path = NCF_SOURCE_PATH.join("events")
    if Dir.exist?(events_path)
      Dir.glob(events_path.join("*.markdown")).each do |file|
        data = parse_markdown_file(file)
        fm = data[:frontmatter]

        next if fm['title'].blank?

        event = Event.find_by(title: fm['title'])
        next unless event

        # Skip if already has an image
        if event.image.attached?
          puts "Event '#{event.title}' already has an image, skipping"
          next
        end

        # Look for image in frontmatter
        image_path = fm['image'] || fm['poster'] || fm['flyer']
        if image_path
          attach_image_from_source(
            event, :image, image_path,
            use_local: use_local_files,
            ncf_source_path: NCF_SOURCE_PATH,
            old_site_url: OLD_SITE_URL
          )
        end
      end
    end

    # Import Post Featured Images
    puts "\n=== Importing Post Featured Images ==="
    news_path = NCF_SOURCE_PATH.join("news")
    if Dir.exist?(news_path)
      Dir.glob(news_path.join("*.markdown")).each do |file|
        data = parse_markdown_file(file)
        fm = data[:frontmatter]

        next if fm['title'].blank?

        base_slug = fm['title'].parameterize
        post = Post.find_by(slug: base_slug)
        next unless post

        # Skip if already has an image
        if post.featured_image.attached?
          puts "Post '#{post.title}' already has a featured image, skipping"
          next
        end

        # Look for image in frontmatter
        image_path = fm['image'] || fm['featured_image']
        if image_path
          attach_image_from_source(
            post, :featured_image, image_path,
            use_local: use_local_files,
            ncf_source_path: NCF_SOURCE_PATH,
            old_site_url: OLD_SITE_URL
          )
        end
      end
    end

    # Import Gallery Member Avatars
    puts "\n=== Importing Gallery Member Avatars ==="
    gallery_path = NCF_SOURCE_PATH.join("..", "data", "gallery.yml")
    if File.exist?(gallery_path)
      gallery_data = YAML.load_file(gallery_path)

      gallery_data['members']&.each do |member|
        email = "#{member['name'].parameterize}@imported.example"
        user = User.find_by(email_address: email)
        next unless user

        profile = user.profile
        next unless profile

        # Skip if already has an avatar
        if profile.avatar.attached?
          puts "Profile '#{profile.name}' already has an avatar, skipping"
          next
        end

        # Look for image in gallery data
        image_path = member['image'] || member['avatar'] || member['photo']
        if image_path
          attach_image_from_source(
            profile, :avatar, image_path,
            use_local: use_local_files,
            ncf_source_path: NCF_SOURCE_PATH,
            old_site_url: OLD_SITE_URL
          )
        end
      end
    end

    puts "\n=== Image Import Complete ==="
  end
end
