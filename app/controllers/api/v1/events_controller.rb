module Api
  module V1
    class EventsController < ResourceController
      permits :title, :description, :rich_description, :bio, :capacity, :doors_at, :starts_at,
              :ends_at, :links, :published, :ticket_price_cents, :ticket_url, :ticketing_enabled,
              :tickets_available_from, :venue_address, :venue_name, :user_id
    end
  end
end
