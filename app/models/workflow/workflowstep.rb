class Workflow::Workflowstep
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning
  include Mongoid::Userstamp
  include SetCurrentUser

  field :title
  field :description
  field :question

  def self.from_hash(step)
    Workflow::Workflowstep.new(step)
  end

end 

