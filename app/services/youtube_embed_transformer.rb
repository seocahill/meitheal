class YoutubeEmbedTransformer
  YOUTUBE_RE = %r{
    \Ahttps?://(?:www\.)?
    (?:youtube\.com/watch\?(?:.*&)?v=|youtu\.be/)
    ([a-zA-Z0-9_-]{11})
  }x

  def self.call(html)
    doc = Nokogiri::HTML::DocumentFragment.parse(html)

    doc.css("a").each do |a|
      href = a["href"].to_s
      next unless (match = href.match(YOUTUBE_RE))
      next unless a.text.strip == href

      video_id = match[1]
      a.replace(embed_html(video_id))
    end

    doc.to_html
  end

  def self.embed_html(video_id)
    Nokogiri::HTML::DocumentFragment.parse(
      %(<div class="aspect-video my-4 rounded overflow-hidden">) +
      %(<iframe src="https://www.youtube.com/embed/#{video_id}" ) +
      %(frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" ) +
      %(allowfullscreen class="w-full h-full"></iframe></div>)
    )
  end
  private_class_method :embed_html
end
