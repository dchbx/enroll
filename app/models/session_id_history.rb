class SessionIdHistory
  include Mongoid::Document
  include Mongoid::Timestamps

  field :session_user_id,  type: String
  field :session_id, type: String

  index({ session_user_id: 1})
  index({ session_id: 1})
end 
  