class SecurityQuestion
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :visible, type: Boolean, default: true

  validates_presence_of :title
  scope :visible, -> { where(visible: true) }

  def status
    visible? ? 'Visible' : 'Invisible'
  end

  def safe_to_edit_or_delete?
    !User.has_answered_question? self.id.to_s
  end
end
