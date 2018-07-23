module SetCurrentUser
  def update_user
    # self.updated_by_id = SAVEUSER[:current_user_id]
  end
  def save_user
    # self.updated_by_id = SAVEUSER[:current_user_id]
  end
  def self.included(klass)
    klass.before_save :save_user
    klass.before_update :update_user
    klass.field :updated_by_id, type: BSON::ObjectId
  end
end
