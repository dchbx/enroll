class Message
  include Mongoid::Document

  embedded_in :inbox

  FOLDER_TYPES = {inbox: "inbox", sent: "sent", deleted: "deleted"}

  field :sender_id, type: BSON::ObjectId
  field :parent_message_id, type: BSON::ObjectId
  field :subject, type: String
  field :body, type: String
  field :message_read, type: Boolean, default: false
  field :folder, type: String
  field :created_at, type: DateTime
  field :from, type: String
  field :to, type: String

  before_create :set_timestamp

  validate :message_has_content

  scope :by_message_id, ->(id){where(:id => id)}

  alias_method :message_read?, :message_read

private
  def set_timestamp
    self.created_at = Time.now.utc
  end

  def message_has_content
    errors.add(:base, "message subject and body cannot be blank") if subject.blank? && body.blank?
  end

end
