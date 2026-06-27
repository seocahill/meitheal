class Chat < ApplicationRecord
  acts_as_chat messages_foreign_key: :chat_id
  has_many :newsletters, dependent: :nullify
end
