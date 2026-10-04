require_relative "../../lib/reject_ip_spoof"
Rails.application.config.middleware.insert_before Rails::Rack::Logger, RejectIpSpoof
