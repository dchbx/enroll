class SecurityQuestion
  include Mongoid::Document

  field :title, type: String
  field :visible, type: Boolean, default: true
end
