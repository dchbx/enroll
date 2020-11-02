module Transcripts

  class PersonError < StandardError; end

  class PersonTranscript

    attr_accessor :transcript
    include Transcripts::Base

    def initialize
      @transcript = transcript_template
      @fields_to_ignore ||= ['_id', 'user_id', 'version', 'created_at', 'updated_at', 'encrypted_ssn', 'ethnicity', 
        'updated_by', 'no_ssn', 'location_state_code', 'updated_by_id', 'is_incarcerated', 'no_dc_address',
        "is_homeless", "is_temporarily_out_of_state", "tribal_id"]

      @custom_templates = []
    end

    def find_or_build(person)
      @transcript[:other] = person
      @transcript[:identifier] = person.hbx_id

      people = match_instance(person)

      case people.count
      when 0
        @transcript[:source_is_new] = true
        @transcript[:source] = initialize_person
      when 1
        @transcript[:source_is_new] = false
        @transcript[:source] = people.first
      else
        message = "Ambiguous person match: more than one person matches criteria"
        raise Factories::Transcripts::PersonError message
      end

      compare_instance
      # validate_instance

      @transcript[:source]  = @transcript[:source].serializable_hash
      @transcript[:other]   = @transcript[:other].serializable_hash
    end


    def self.enumerated_associations
      [
        {association: "addresses", enumeration_field: "kind", cardinality: "many", enumeration: ["branch"]},
        {association: "addresses", enumeration_field: "kind", cardinality: "one", enumeration: ["home", "work", "mailing", "primary"]},
        {association: "person_relationships", enumeration_field: "kind", cardinality: "one", enumeration: ["self", "spouse", "life_partner"]},
        {association: "person_relationships", enumeration_field: "kind", cardinality: "many", enumeration: ["child", "adopted_child", "foster_child", "grandchild", "parent", "grandparent"]},
        {association: "phones", enumeration_field: "kind", cardinality: "one", enumeration: Phone::KINDS },
        {association: "emails", enumeration_field: "kind", cardinality: "one", enumeration: Email::KINDS },
      ]
    end

    private

    def match_instance(person)
      if person.hbx_id.present?
        matched_people = ::Person.where(hbx_id: person.hbx_id)
      end

      if matched_people.blank?
        matched_people = ::Person.match_by_id_info(
            ssn: person.ssn,
            dob: person.dob,
            last_name: person.last_name,
            first_name: person.first_name
          )
      end

      matched_people
    end

    def initialize_person
      fields = ::Person.new.fields.inject({}){|data, (key, val)| data[key] = val.default_val; data }
      fields.delete_if{|key,_| @fields_to_ignore.include?(key)}
      ::Person.new(fields)
    end
  end
end
