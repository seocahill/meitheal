module InboxHelper
  def format_zoho_time(timestamp_ms)
    return "" unless timestamp_ms

    time = Time.at(timestamp_ms.to_i / 1000)
    if time.to_date == Date.current
      time.strftime("%l:%M %p").strip
    elsif time.to_date == Date.yesterday
      "Yesterday"
    elsif time > 7.days.ago
      time.strftime("%a")
    else
      time.strftime("%b %d")
    end
  end

  def format_zoho_datetime(timestamp_ms)
    return "" unless timestamp_ms

    time = Time.at(timestamp_ms.to_i / 1000)
    time.strftime("%B %d, %Y at %l:%M %p").strip
  end
end
