  module Transcripts
  class FamilyTranscriptError < StandardError; end

  class FamilyTranscript

    attr_accessor :transcript, :primary_hbx_id
    include Transcripts::Base

    def initialize
      @transcript = transcript_template

      @logger = Logger.new("#{Rails.root}/log/family_transcript_logfile.log")
      @fields_to_ignore ||= ['_id', 'user_id', 'version', 'created_at', 'updated_at', 'updated_by', 'updated_by_id', 'first_name', 'last_name']

      @custom_templates = ['FamilyMember']
    end

    def convert(record)
      return if record.blank?
      {
        :hbx_id => record.hbx_id,
        :is_primary_applicant => record.is_primary_applicant,
        :relationship => find_relationship(record),
        :first_name => record.first_name,
        :last_name => record.last_name
      }
    end

    def find_relationship(family_member)
      return family_member.primary_relationship if family_member.persisted?
      
      if family_member.is_primary_applicant
        'self'
      else
        family_member.person.person_relationships.first.try(:kind)
      end
    end

    def find_or_build(family)
      @transcript[:other] = family
      matched_family = match_instance(family)

      if matched_family.blank?
        @transcript[:source_is_new] = true
        @transcript[:source] = initialize_family
      else
        @transcript[:source_is_new] = false
        @transcript[:source] = matched_family
      end

      # case families.count
      # when 0
      #   @transcript[:source_is_new] = true
      #   @transcript[:source] = initialize_family
      # when 1
      #   @transcript[:source_is_new] = false
      #   @transcript[:source] = families.first
      # else
      #   raise "Ambiguous family match: more than one family matches criteria"
      # end

      compare_instance
      # validate_instance

      @transcript[:source]  = @transcript[:source].serializable_hash
      @transcript[:other]   = @transcript[:other].serializable_hash
    end

    def compare_instance
      return if @transcript[:other].blank?
      differences    = HashWithIndifferentAccess.new

      if @transcript[:source_is_new]
        differences[:new] = {:new => {:e_case_id => @transcript[:other].e_case_id}}
        @transcript[:compare] = differences
        return
      end

      differences[:base] = compare(base_record: @transcript[:source], compare_record: @transcript[:other])

      self.class.enumerated_associations.each do |association|
        differences[association[:association]] = build_association_differences(association)
      end

      @transcript[:compare] = differences
    end

    def self.enumerated_associations
      [
        {association: "family_members", enumeration_field: "hbx_id", cardinality: "one", enumeration: [ ]},
        {association: "irs_groups", enumeration_field: "hbx_assigned_id", cardinality: "one", enumeration: [ ]}
      ]
    end

    private

    def match_instance(family)
      primary = family.primary_applicant

      @primary_hbx_id = primary.person.hbx_id
      matches = match_person_instance(primary.person)

      if matches.size > 1
        raise 'found more than 1 primary match'
      end

      primary_person = primary.person
      primary_person = matches[0] if matches.present?

      @transcript[:primary_details] = {
        hbx_id: primary_person.hbx_id,
        first_name: primary_person.first_name,
        last_name: primary_person.last_name,
        ssn: primary_person.ssn
      }

      @transcript[:identifier] = primary_person.hbx_id

      return nil if matches.blank?
      matches[0].primary_family
    end

     def match_person_instance(person)
      if person.hbx_id.present?
        matched_people = ::Person.where(hbx_id: person.hbx_id) || []
      else
        matched_people = ::Person.match_by_id_info(
            ssn: person.ssn,
            dob: person.dob,
            last_name: person.last_name,
            first_name: person.first_name
          )
      end
      matched_people
    end

    def initialize_family
      fields = ::Family.new.fields.inject({}){|data, (key, val)| data[key] = val.default_val; data }
      fields.delete_if{|key,_| @fields_to_ignore.include?(key)}
      ::Family.new(fields)
    end

  end
end