class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Userstamp

  PRIORITY_KINDS = %w(low normal high)

  embedded_in :commentable, polymorphic: true

  before_save :set_priority

  field :content, type: String
  field :is_priority, type: Boolean, default: false
  field :priority, type: String, default: "normal"
  field :user, type: String

  validates_inclusion_of :priority, in: PRIORITY_KINDS, message: "Invalid priority"
  validates_presence_of :content

  embedded_in :person
  embedded_in :special_enrollment_period

  def high?
    priority == "high"
  end

  def low?
    priority == "low"
  end

  private
    def set_priority
      is_priority = true if high?
    end
end
