require "test_helper"

class YoutubeEmbedTransformerTest < ActiveSupport::TestCase
  def transform(html)
    YoutubeEmbedTransformer.call(html)
  end

  test "transforms bare youtube.com watch link to iframe" do
    html = '<p><a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ">https://www.youtube.com/watch?v=dQw4w9WgXcQ</a></p>'
    result = transform(html)
    assert_match 'src="https://www.youtube.com/embed/dQw4w9WgXcQ"', result
    assert_no_match "youtube.com/watch", result
  end

  test "transforms bare youtu.be short link to iframe" do
    html = '<p><a href="https://youtu.be/dQw4w9WgXcQ">https://youtu.be/dQw4w9WgXcQ</a></p>'
    result = transform(html)
    assert_match 'src="https://www.youtube.com/embed/dQw4w9WgXcQ"', result
  end

  test "does not transform link with descriptive text" do
    html = '<p><a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ">Watch this video</a></p>'
    result = transform(html)
    assert_no_match "<iframe", result
    assert_match "Watch this video", result
  end

  test "does not transform non-youtube links" do
    html = '<p><a href="https://vimeo.com/123456">https://vimeo.com/123456</a></p>'
    result = transform(html)
    assert_no_match "<iframe", result
    assert_match "vimeo.com", result
  end

  test "transforms multiple youtube links in one document" do
    html = '<p><a href="https://youtu.be/aaaaaaaaaaa">https://youtu.be/aaaaaaaaaaa</a></p>' \
           '<p><a href="https://youtu.be/bbbbbbbbbbb">https://youtu.be/bbbbbbbbbbb</a></p>'
    result = transform(html)
    assert_match "embed/aaaaaaaaaaa", result
    assert_match "embed/bbbbbbbbbbb", result
  end

  test "leaves unrelated html untouched" do
    html = "<p>Hello <strong>world</strong></p>"
    assert_equal html, transform(html)
  end
end
