module EventPublishers::Base
  include Acapi::Notifiers
  class MethodNotImplementedError < StandardError; end

  CANONICAL_VOCABULARY_URI_V1 = "urn:openhbx:events:v1:"

  before_save :build_transcript

  # build transcript with change_set
  # send change_set to appropriate module in event_publishers folder
  # compare against change_signatures
  # identify event for each change_signature match
  # publish event to enterprise via ACAPI gem

  ## Add logger here

  def initialize(options={})
    @options = options

    super
    # raise ArgumentError, "" unless options.has_key?(:transcript)
    @klass_name = transcript[:source].class.name.underscore
    @change_set = transcript[:changes]
  end

  def klass
    self.class.name.classify.constantize
  end

  def build_transcript
  end

  def change_set_event(change_set_item)
  end

  def change_set_signature
    {
      klass_name: "employer_profile",
      change_criteria: { 
          local_event: "",
          aasm_state: ""
        }
      }
  end


  def self.included(base)
    base.extend ClassMethods

    # base.class_eval do
    #   aasm do
    #     after_all_transitions :publish_transition
    #   end
    # end
  end

  module ClassMethods

    def enterprise_events
      enterprise_events ||= []
    end

    def local_events
      local_events ||= []
    end

    def change_key_set(changes)
      changes.keys.to_set if changes.length > 0
    end

    def change_signatures
      raise MethodNotImplementedError, 'Please implement this method in your class.'
    end

    change_signature = 
    { klass_name: "",

      }

    def parse(changes = [])
      changed_field_set = changes.keys.to_set
      changed_field_set.intersect?()
      myarray.to_set.intersect?(values.to_set)
    end

    def publish_transition
      resource_mapping = ApplicationEventMapper.map_resource(self.class)
      event_name = ApplicationEventMapper.map_event_name(resource_mapping, aasm.current_event)
      notify(event_name, {resource_mapping.identifier_key => self.send(resource_mapping.identifier_method).to_s})
    end


  private
    # Build the Mongoid::History options
    def audit_history_options(options = {})
      options.present? ? options : default_options
    end

    # Default options: 
    ## Track all fields and relations
    ## Track all action types
    def default_options
      {
        on: self.fields.keys + self.relations.keys,
        except: [:created_at, :updated_at], 
        tracker_class_name: nil,
        modifier_field: :updated_by,
        changes_method: :changes,
        version_field: :version,
        scope: :person,
        track_create: true, 
        track_update: true, 
        track_destroy: true
      }
    end
  end




end
