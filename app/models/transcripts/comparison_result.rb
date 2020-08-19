module Transcripts
  class ComparisonResult
    attr_reader :person, :changeset

    EVENT_NAMESPACE_PREFIX  = ""
    CHANGE_ACTION_KINDS     = %w(add remove update new)

    CHANGE_EVENT_KINDS      = %w(identifier name demographic address communication)

    IDENTIFIER_FIELDS       = %w(hbx_id ssn tin)
    NAME_FIELDS             = %w(first_name last_name middle_name name_pfx name_sfx)
    DEMOGRAPHIC_FIELDS      = %w(gender dob date_of_death marital_status ethnicity citizenship_status)

    ADDRESS_FIELDS          = %w(addresses)
    COMMUNICATION_FIELDS    = %w(emails phones)

    DISABILITY_FIELDS       = %w(disability_kind )
    DISABILITY_KINDS        = %w(short_term_disability long_term_disability permanent_disability no_disability)
    LANGUAGE_FIELDS         = %w(language_code)

    PLAN_CHANGE_FIELDS      = %w(cobra_begin cobra_end)

    BASE_PATH     = [:base]
    ADDRESS_PATH  = [:addresses]
    EMAILS_PATH   = [:emails]
    PHONES_PATH   = [:phones]

    def initialize(person = HashWithIndifferentAccess.new)
      @person = person
      # @person = Payload.new().person
      @changeset = @person[:compare]
    end

    def changeset_events
      # CHANGE_EVENT_KINDS.reduce([]) { |events, group| events << send("#{group}_events".to_sym) }
    end

    def changeset_sections
      changeset.keys.collect { |k| "#{k}".to_sym }
    end

    # Access content using array of one or multiple nested hash key(s)
    def changeset_content_at(path = [])
      return ArgumentError, "path must be an array" unless path.is_a? Array
      path.reduce(changeset) { |map, step| map[step] }
    end

    def changeset_section_actions(section)
     changeset_content_at(section).keys || []
    end

    def changeset_section_attributes_by_action(section, change_action)
      unless CHANGE_ACTION_KINDS.include?(change_action.to_s)
        return ArgumentError, "invalid change_action keyword"
      end 
      changeset_content_at([section, change_action]).keys
    end

    def changeset_section_values_by_action(section, change_action)
      unless CHANGE_ACTION_KINDS.include?(change_action.to_s)
        return ArgumentError, "invalid change_action keyword"
      end 
      changeset_content_at([section, change_action]).values
    end

    def name_change
    end

    def address_change
    end

    def changeset_value_at(path = [])
      changeset_content_at(path).values if changeset_content_at(path).present?
    end

    def csv_row
      if @person[:source_is_new]
        person_details = [@person[:other]['hbx_id'], Person.decrypt_ssn(@person[:other]['encrypted_ssn']), @person[:other]['last_name'], @person[:other]['first_name']]
      else
        person_details = [@person[:source]['hbx_id'], Person.decrypt_ssn(@person[:source]['encrypted_ssn']), @person[:source]['last_name'], @person[:source]['first_name']]
      end

      results = changeset_sections.reduce([]) do |section_rows, section|
        actions = changeset_section_actions [section]
        section_rows += actions.reduce([]) do |rows, action|
          attributes = changeset_content_at [section, action]
    
          fields_to_ignore = ['_id', 'updated_by']
          rows += attributes.collect do |attribute, value|
            if value.is_a?(Hash)
              fields_to_ignore.each{|key| value.delete(key) }
              value.each{|k, v| fields_to_ignore.each{|key| v.delete(key) } if v.is_a?(Hash) }
            end

            (person_details + [action, "#{section}:#{attribute}", value])
          end
        end
      end

      if results.blank?
        [person_details + ['update']]
      else
        results
      end
    end

    def family_csv_row
      changeset_sections.reduce([]) do |section_rows, section|
        actions = changeset_section_actions [section]
        section_rows += actions.reduce([]) do |rows, action|
          attributes = changeset_content_at [section, action]

          person_details = [
              @person[:primary_details][:hbx_id],
              @person[:primary_details][:ssn], 
              @person[:primary_details][:last_name], 
              @person[:primary_details][:first_name]
          ]

          fields_to_ignore = ['_id', 'updated_by']
          rows += attributes.collect do |attribute, value|

            if value.is_a?(Hash)
              fields_to_ignore.each{|key| value.delete(key) }
              value.each{|k, v| fields_to_ignore.each{|key| v.delete(key) } if v.is_a?(Hash) }
            end

            (person_details + [action, "#{section}:#{attribute}", value])
          end
        end
      end
    end

    def enrollment_csv_row
      changeset_sections.reduce([]) do |section_rows, section|
        actions = changeset_section_actions [section]
        section_rows += actions.reduce([]) do |rows, action|
          attributes = changeset_content_at [section, action]

          person_details = [
              @person[:primary_details][:hbx_id],
              @person[:primary_details][:ssn], 
              @person[:primary_details][:last_name], 
              @person[:primary_details][:first_name]
          ]

          fields_to_ignore = ['_id', 'updated_by']
          rows = []
          attributes.each do |attribute, value|
            if value.is_a?(Hash)
              fields_to_ignore.each{|key| value.delete(key) }
              value.each{|k, v| fields_to_ignore.each{|key| v.delete(key) } if v.is_a?(Hash) }
            end

            plan_details = (@person[:plan_details].present? ? @person[:plan_details].values : 4.times.map{nil})

            # ([@person[:identifier]] + person_details + plan_details + [action, "#{section}:#{attribute}", value])
            # employer_details = (@person[:employer_details].present? ? @person[:employer_details].values : 3.times.map{nil})

            # if value.is_a?(Array)
            #   value.each{|val| rows << ([@person[:identifier]] + person_details + plan_details + employer_details + [action, "#{section}:#{attribute}", val]) }
            # else
            #   rows << ([@person[:identifier]] + person_details + plan_details + employer_details + [action, "#{section}:#{attribute}", value])
            # end


            if value.is_a?(Array)
              value.each{|val| rows << ([@person[:identifier]] + person_details + plan_details + [action, "#{section}:#{attribute}", val]) }
            else
              rows << ([@person[:identifier]] + person_details + plan_details + [action, "#{section}:#{attribute}", value])
            end   
          end

          rows
        end
      end
    end


    def csv_header
    end

    def nodes
      HashWithIndifferentAccess.new(
        person_hbx_id:      { hash_path: "[:hbx_id]", title: "HBX ID" },
        person_last_name:   { hash_path: "[:last_name]", title: "Last Name" },
        person_first_name:  { hash_path: "[:first_name]", title: "First Name" },

        person_addresses:   { hash_path: "[:addresses]", title: "Addresses" },
        person_phones:      { hash_path: "[:phones]", title: "Phones" },
        person_emails:      { hash_path: "[:emails]", title: "Emails" },

        person_created_at:  { hash_path: "[:created_at]", title: "Created At" },
        person_updated_at:  { hash_path: "[:updated_at]", title: "Updated At" },
        phone_created_at:   { hash_path: "[:created_at]", title: "Created At" },
      )
    end

    def disability
      {
        id_kinds: [{dx: "icd-9-cm"}, {zz: "mutually_defined (icd-10-cm"}],
        code_kinds: []
      }
    end
  end

  class Payload
    def metadata
      HashWithIndifferentAccess.new(
        :metadata => {
            origin: "enroll_application",
            created_at: "06 Oct 2016".to_datetime,
          }
        )
    end

    def person
      Marshal.load(File.open("#{Rails.root}/sample_file"))
    end

    # def person
    #   HashWithIndifferentAccess.new(
    #   :source=>
    #   {
    #      "_id"=>BSON::ObjectId('57faba61fb9cdd52da000003'),
    #    "addresses"=>
    #     [{"_id"=>BSON::ObjectId('57faba61fb9cdd52da000000'),
    #       "address_1"=>"3312 H St NW",
    #       "address_2"=>"",
    #       "address_3"=>"",
    #       "city"=>"Washington",
    #       "country_name"=>"",
    #       "county"=>nil,
    #       "created_at"=>"Sun, 09 Oct 2016 21:45:05 UTC +00:00",
    #       "full_text"=>nil,
    #       "kind"=>"home",
    #       "location_state_code"=>nil,
    #       "state"=>"DC",
    #       "updated_at"=>"Sun, 09 Oct 2016 21:45:05 UTC +00:00",
    #       "zip"=>"20002"}],
    #    "alternate_name"=>nil,
    #    "broker_agency_contact_id"=>nil,
    #    "created_at"=>"Sun, 09 Oct 2016 21:45:05 UTC +00:00",
    #    "date_of_death"=>nil,
    #    "dob"=>"Fri, 01 Aug 1975",
    #    "dob_check"=>nil,
    #    "emails"=>
    #     [{"_id"=>BSON::ObjectId('57faba61fb9cdd52da000002'),
    #       "address"=>"test@gmail.com",
    #       "created_at"=>"Sun, 09 Oct 2016 21:45:05 UTC +00:00",
    #       "kind"=>"home",
    #       "updated_at"=>"Sun, 09 Oct 2016 21:45:05 UTC +00:00"}],
    #    "employer_contact_id"=>nil,
    #    "encrypted_ssn"=>"QEVuQwIAGuOo+D/KqGBzlCMhVFxFKw==",
    #    "ethnicity"=>nil,
    #    "first_name"=>"Bruce",
    #    "full_name"=>"Bruce Jackson",
    #    "gender"=>"male",
    #    "general_agency_contact_id"=>nil,
    #    "hbx_id"=>"117966",
    #    "inbox"=>
    #     {"_id"=>BSON::ObjectId('57faba61fb9cdd52da000004'),
    #      "access_key"=>"57faba61fb9cdd52da000004d184081ec17107a18efd",
    #      "messages"=>
    #       [{"_id"=>BSON::ObjectId('57faba61fb9cdd52da000005'),
    #         "body"=>"DC Health Link is the District of Columbia's on-line marketplace to shop, compare, and select health insurance that meets your health needs and budgets.",
    #         "created_at"=>"Sun, 09 Oct 2016 21:45:05 +0000",
    #         "folder"=>nil,
    #         "from"=>"DC Health Link",
    #         "message_read"=>false,
    #         "parent_message_id"=>nil,
    #         "sender_id"=>nil,
    #         "subject"=>"Welcome to DC Health Link",
    #         "to"=>nil}]},
    #    "is_active"=>true,
    #    "is_disabled"=>nil,
    #    "is_incarcerated"=>nil,
    #    "is_tobacco_user"=>"unknown",
    #    "language_code"=>nil,
    #    "last_name"=>"Jackson",
    #    "middle_name"=>nil,
    #    "name_pfx"=>nil,
    #    "name_sfx"=>nil,
    #    "no_dc_address"=>false,
    #    "is_homeless"=>"",
    #    "is_temporarily_out_of_state"=>"",
    #    "no_ssn"=>nil,
    #    "phones"=>
    #     [{"_id"=>BSON::ObjectId('57faba61fb9cdd52da000001'),
    #       "area_code"=>"202",
    #       "country_code"=>"",
    #       "created_at"=>"Sun, 09 Oct 2016 21:45:05 UTC +00:00",
    #       "extension"=>"",
    #       "full_phone_number"=>"2029867777",
    #       "kind"=>"mobile",
    #       "number"=>"9867777",
    #       "primary"=>nil,
    #       "updated_at"=>"Sun, 09 Oct 2016 21:45:05 UTC +00:00"}],
    #    "race"=>nil,
    #    "tribal_id"=>nil,
    #    "updated_at"=>"Sun, 09 Oct 2016 21:45:05 UTC +00:00",
    #    "updated_by"=>nil,
    #    "updated_by_id"=>nil,
    #    "user_id"=>nil,
    #    "version"=>1},
    #  :other=>
    #   {"_id"=>BSON::ObjectId('57faba67fb9cdd52da000006'),
    #    "addresses"=>
    #     [{"_id"=>BSON::ObjectId('57faba67fb9cdd52da000007'),
    #       "address_1"=>"3312 Gosnell Rd",
    #       "address_2"=>"",
    #       "address_3"=>"",
    #       "city"=>"Vienna",
    #       "country_name"=>"",
    #       "county"=>nil,
    #       "created_at"=>nil,
    #       "full_text"=>nil,
    #       "kind"=>"home",
    #       "location_state_code"=>nil,
    #       "state"=>"VA",
    #       "updated_at"=>nil,
    #       "zip"=>"22180"},
    #      {"_id"=>BSON::ObjectId('57faba67fb9cdd52da000008'),
    #       "address_1"=>"609 L St NW",
    #       "address_2"=>"",
    #       "address_3"=>"",
    #       "city"=>"Washington",
    #       "country_name"=>"",
    #       "county"=>nil,
    #       "created_at"=>nil,
    #       "full_text"=>nil,
    #       "kind"=>"work",
    #       "location_state_code"=>nil,
    #       "state"=>"DC",
    #       "updated_at"=>nil,
    #       "zip"=>"20002"}],
    #    "alternate_name"=>nil,
    #    "broker_agency_contact_id"=>nil,
    #    "created_at"=>nil,
    #    "date_of_death"=>nil,
    #    "dob"=>"Sun, 01 Jun 1975",
    #    "dob_check"=>nil,
    #    "emails"=>[{"_id"=>BSON::ObjectId('57faba67fb9cdd52da000009'), "address"=>"bruce@gmail.com", "created_at"=>nil, "kind"=>"home", "updated_at"=>nil}],
    #    "employer_contact_id"=>nil,
    #    "encrypted_ssn"=>"QEVuQwIAbfJD0Py+mEJnYKRIKrEGcA==",
    #    "ethnicity"=>nil,
    #    "first_name"=>"Bruce",
    #    "full_name"=>"Bruce Jackson",
    #    "gender"=>"male",
    #    "general_agency_contact_id"=>nil,
    #    "hbx_id"=>"117966",
    #    "is_active"=>true,
    #    "is_disabled"=>nil,
    #    "is_incarcerated"=>nil,
    #    "is_tobacco_user"=>"unknown",
    #    "language_code"=>nil,
    #    "last_name"=>"Jackson",
    #    "middle_name"=>nil,
    #    "name_pfx"=>nil,
    #    "name_sfx"=>nil,
    #    "no_dc_address"=>false,
    #    "is_homeless"=>"",
    #    "is_temporarily_out_of_state"=>"",
    #    "no_ssn"=>nil,
    #    "phones"=>
    #     [{"_id"=>BSON::ObjectId('57faba67fb9cdd52da00000a'),
    #       "area_code"=>"202",
    #       "country_code"=>"",
    #       "created_at"=>nil,
    #       "extension"=>"",
    #       "full_phone_number"=>"2029866677",
    #       "kind"=>"home",
    #       "number"=>"9866677",
    #       "primary"=>nil,
    #       "updated_at"=>nil}],
    #    "race"=>nil,
    #    "tribal_id"=>nil,
    #    "updated_at"=>nil,
    #    "updated_by"=>nil,
    #    "updated_by_id"=>nil,
    #    "user_id"=>nil,
    #    "version"=>1},
    #  :compare=>
    #   {"base"=>{"update"=>{"dob"=>1975-06-01 00:00:00 UTC}},
    #    "addresses"=> 
    #     {"update"=>{"home"=>{
    #       "update"=>{"address_1"=>"3312 Gosnell Rd", "city"=>"Vienna", "state"=>"VA", "zip"=>"22180"}}},
    #      "add"=>
    #       {"work"=>
    #         {"_id"=>BSON::ObjectId('57faba67fb9cdd52da000008'),
    #          "address_1"=>"609 L St NW",
    #          "address_2"=>"",
    #          "address_3"=>"",
    #          "city"=>"Washington",
    #          "country_name"=>"",
    #          "county"=>nil,
    #          "created_at"=>nil,
    #          "full_text"=>nil,
    #          "kind"=>"work",
    #          "location_state_code"=>nil,
    #          "state"=>"DC",
    #          "updated_at"=>nil,
    #          "zip"=>"20002"}}},
    #    "person_relationships"=>{},
    #    "phones"=>
    #     {"add"=>
    #       {"home"=>
    #         {"_id"=>BSON::ObjectId('57faba67fb9cdd52da00000a'),
    #          "area_code"=>"202",
    #          "country_code"=>"",
    #          "created_at"=>nil,
    #          "extension"=>"",
    #          "full_phone_number"=>"2029866677",
    #          "kind"=>"home",
    #          "number"=>"9866677",
    #          "primary"=>nil,
    #          "updated_at"=>nil}},
    #      "remove"=>
    #       {"mobile"=>
    #         {"_id"=>BSON::ObjectId('57faba61fb9cdd52da000001'),
    #          "area_code"=>"202",
    #          "country_code"=>"",
    #          "created_at"=>"Sun, 09 Oct 2016 21:45:05 UTC +00:00",
    #          "extension"=>"",
    #          "full_phone_number"=>"2029867777",
    #          "kind"=>"mobile",
    #          "number"=>"9867777",
    #          "primary"=>nil,
    #          "updated_at"=>"Sun, 09 Oct 2016 21:45:05 UTC +00:00"}}},
    #    "emails"=>{"update"=>{"home"=>{"update"=>{"address"=>"bruce@gmail.com"}}}}},
    #  :source_errors=>{},
    #  :other_errors=>{},
    #  :source_is_new=>false)
    # end
  end
end
