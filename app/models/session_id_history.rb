class SessionIdHistory
  include Mongoid::Document
  include Mongoid::Timestamps

  field :session_user_id,  type: String
  field :session_id, type: String
  field :sign_in_outcome, type: String
  field :ip_address, type: String

  index({ session_user_id: 1})
  index({ session_id: 1})

  class << self
    def for_user(user_id:)
      self.where(session_user_id: user_id)
    end
  end
end
