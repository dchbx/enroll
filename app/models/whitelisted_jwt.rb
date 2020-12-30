class WhitelistedJwt
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user

  field :jti, type: String
  field :exp, type: String
  field :token, type: String

  # If you want to leverage the `aud` claim, add to it a `NOT NULL` constraint:
  # t.string :aud, null: false
  field :aud, type: String

  validates :jti, :exp, presence: true

  index({:user_id => 1, :jti => 1})
  index({:jti => 1, :aud => 1, :user_id => 1, :created_at => 1})
  index({:exp => 1})

  #add_index :whitelisted_jwts, :jti, unique: true

  def self.newest
    order_by(:created_at => :desc).first
  end
end