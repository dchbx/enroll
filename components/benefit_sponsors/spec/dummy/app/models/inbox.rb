class Inbox
  include Mongoid::Document

  field :access_key, type: String

  # Enable polymorphic associations
  embedded_in :recipient, polymorphic: true
  embeds_many :messages
  accepts_nested_attributes_for :messages

  before_create :generate_acccess_key

  def read_messages
    messages.where(message_read: true, folder: Message::FOLDER_TYPES[:inbox])
  end

  def unread_messages
    messages.where(message_read: false, folder: Message::FOLDER_TYPES[:inbox]) +
    messages.where(message_read: false, folder: nil)
  end

  def post_message(new_message)
    self.messages.push new_message
    self
  end

  def delete_message(message)
    return self if self.messages.size == 0
    message = self.messages.detect { |m| m.id == message.id }
    message.delete unless message.nil?
    self
  end

private
  def generate_acccess_key
    self.access_key = [id.to_s, SecureRandom.hex(10)].join
  end
end
