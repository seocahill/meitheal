# Use this hook to configure the litestream-ruby gem.
# All configuration options will be available as environment variables, e.g.
# config.replica_bucket becomes LITESTREAM_REPLICA_BUCKET
# This allows you to configure Litestream using Rails encrypted credentials,
# or some other mechanism where the values are only available at runtime.

Rails.application.configure do
  # Configure Litestream using AWS credentials from Rails encrypted credentials
  config.litestream.replica_bucket = "meitheal-litefs-backups"
  config.litestream.replica_key_id = Rails.application.credentials.aws_access_key_id
  config.litestream.replica_access_key = Rails.application.credentials.aws_secret_access_key
  config.litestream.replica_region = "eu-west-1"

  # Configure the default Litestream config path
  # config.config_path = Rails.root.join("config", "litestream.yml")

  # Configure the Litestream dashboard
  #
  # Set the default base controller class
  # config.litestream.base_controller_class = "MyApplicationController"
  #
  # Set authentication credentials for Litestream dashboard
  # Set authentication credentials for Litestream
  config.litestream.username = Rails.application.credentials.dig(:litestream, :username)
  config.litestream.password = Rails.application.credentials.dig(:litestream, :password)
end
