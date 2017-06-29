class Workflow::Workflow
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning
  include Mongoid::Userstamp
  include SetCurrentUser

  embeds_many :workflow_steps

  attr_accessor :workflow_step

  field :person_id, type: BSON::ObjectId

  # validate :person_id

  def current_step
  end

  def completed_steps
  end 

  def remaining_steps
  end

  def completed_workflow?
  end

  def initialize(options={})
    super
    yaml_hash = from_yaml("config/workflow/financial_assistance.yml")
    @workflow_step = {}
    initialize_steps_from_hash(yaml_hash)
    self.person_id = options[:person_id]
  end

  def initialize_steps_from_hash(yaml_hash)
    unless yaml_hash.blank?
      yaml_hash["steps"].each do |key, value|
        @workflow_step[key] = value
      end

      @workflow_step.each do |key, value|
        Workflow::Workflowstep.from_hash(value)
      end
    end
  end

  def from_yaml(filename)
    begin
      yaml_hash = YAML.load_file(filename)
    rescue Exception => e
      puts "The input YAML file is badly formatted---#{e.inspect}" unless Rails.env.test?
    end
    return yaml_hash
  end

  def person
    return @person if @person.present?
    Person.find(self.person_id)
  end
end
