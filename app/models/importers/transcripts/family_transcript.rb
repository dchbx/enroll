module Importers::Transcripts
  
  class StaleRecordError < StandardError; end
  class AmbiguousMatchError < StandardError; end
  class PersonNotFound < StandardError; end
  class FamilyMissingError < StandardError; end

  class FamilyTranscript

    attr_accessor :transcript, :updates, :market, :other_family

    ENUMERATION_FIELDS = {
      family_members: { enumeration_field: "hbx_id", enumeration: [ ] },
      irs_groups: { enumeration_field: "hbx_assigned_id", enumeration: [ ] }
    }

    SUBSCRIBER_SOURCE_RULE_MAP = {

    }

    SOURCE_RULE_MAP = {
      base: {
        add: 'ignore',
        update: 'ignore',
        remove: 'ignore'
      },
      family_members: {
        add: 'edi',
        update: {
          relationship: 'edi'
        },
        remove: 'ignore'
      },
      irs_groups: {
        add: 'ignore',
        update: 'ignore',
        remove: 'ignore'
      }
    }

    def process
      @updates = {}
      @comparison_result = ::Transcripts::ComparisonResult.new(@transcript)

      if @transcript[:source_is_new]
        create_new_family
      else
        @family = find_instance
        raise FamilyMissingError, "Family match not found!" if @family.blank?

        @comparison_result.changeset_sections.reduce([]) do |section_rows, section|
          actions = @comparison_result.changeset_section_actions [section]

          section_rows += actions.reduce([]) do |rows, action|
            attributes = @comparison_result.changeset_content_at [section, action]
            rows << send(action, section, attributes)
          end
        end
      end
    end

    def add(section, attributes)
      rule = find_rule_set(section, :add)

      @updates[:add] ||= {} 
      @updates[:add][section] ||= {}

      if section == :base
        attributes.each do |field, value|
          if rule == 'edi'
          else
            log_ignore(:add, section, field)
          end
        end
      else
        enumerated_association = ENUMERATION_FIELDS[section]

        attributes.each do |identifier, association|
          if rule == 'edi'
            begin
              send("add_#{section}", association)
              log_success(:add, section, identifier)
            rescue Exception => e 
              @updates[:add][section][identifier] = ["Failed", "#{e.inspect}"]
            end
          else
            log_ignore(:add, section, identifier)
          end
        end
      end
    end

    def update(section, attributes)
      rule = find_rule_set(section, :update)

      @updates[:update] ||= {} 
      @updates[:update][section] ||= {} 

      if section == :base
        attributes.each do |field, value|
          if value.present? && (rule == 'edi' || (rule.is_a?(Hash) && rule[field.to_sym] == 'edi'))
          else
            log_ignore(:update, section, field)
          end
        end
      else
        enumerated_association = ENUMERATION_FIELDS[section]

        attributes.each do |identifier, value|

          if rule == 'edi' || (value.values.present? && value.values.first['relationship'].present?)
            if section == :family_members
              hbx_id = identifier.split(':')[1]
              family_member = @family.family_members.detect{|fm| fm.hbx_id == hbx_id}
              if family_member.blank?
                raise "#{section} #{identifier} record missing!"
              end

              value.each do |key, v|
                if v['relationship'].blank?
                  log_ignore(:update, section, identifier)
                  next
                end

                begin
                  validate_timestamp(section)
                  relationships = [['child', 'spouse'],['spouse', 'ward']]

                  if (key == 'add' || key == 'update')
                    if relationships.detect{|pair| pair.include?(v['relationship']) && pair.include?(family_member.relationship)}
                      @family.primary_applicant.person.ensure_relationship_with(family_member.person, v['relationship'], @family.id)
                    else
                      log_ignore(:update, section, identifier)
                    end
                  end

                  log_success(:update, section, identifier)
                rescue Exception => e
                  @updates[:update][section][identifier] = ["Failed", "#{e.inspect}"]
                end
              end
            end
          else
            log_ignore(:update, section, identifier)
          end
        end
      end
    end

    def remove(section, attributes)
      rule = find_rule_set(section, :remove)

      @updates[:remove] ||= {} 
      @updates[:remove][section] ||= {} 

      if section == :base
        attributes.each do |field, value|
          if rule == 'edi' || (rule.is_a?(Hash) && rule[field.to_sym] == 'edi')
          else
            log_ignore(:remove, section, field)
          end
        end
      else
        enumerated_association = ENUMERATION_FIELDS[section]
        attributes.each do |identifier, value|
          if rule == 'edi' || (rule.is_a?(Hash) && rule[identifier.to_sym] == 'edi')
          else
            log_ignore(:remove, section, identifier)
          end
        end
      end
    end

    def csv_row
      @comparison_result.changeset_sections.reduce([]) do |section_rows, section|
        actions = @comparison_result.changeset_section_actions [section]
        section_rows += actions.reduce([]) do |rows, action|
          attributes = @comparison_result.changeset_content_at [section, action]

         person_details = [
              @transcript[:primary_details][:hbx_id],
              @transcript[:primary_details][:ssn], 
              @transcript[:primary_details][:last_name], 
              @transcript[:primary_details][:first_name]
          ]


          fields_to_ignore = ['_id', 'updated_by']

          rows += attributes.collect do |attribute, value|
            if value.is_a?(Hash)
              fields_to_ignore.each{|key| value.delete(key) }
              value.each{|k, v| fields_to_ignore.each{|key| v.delete(key) } if v.is_a?(Hash) }
            end
            (person_details + [action, "#{section}:#{attribute}", value] + (@updates[action.to_sym][section][attribute] || []))
          end
        end
      end
    end

    private

    def log_success(action, section, field)
      kind = (section == :base ? 'attribute' : 'record')
      @updates[action][section][field] = case action
      when :add
        ["Success", "Added #{field} #{kind} on #{section} using EDI source"]
      when :update
        ["Success", "Updated #{field} #{kind} on #{section} using EDI source"]
      else
        ["Success", "Removed #{field} on #{section}"]
      end
    end

    def log_ignore(action, section, field)
      @updates[action][section][field] = ["Ignored", "Ignored per Family update rule set."]
    end

    def find_rule_set(section, action)
      if @market == 'shop'
        SUBSCRIBER_SOURCE_RULE_MAP[section][action]
      else
        SOURCE_RULE_MAP[section][action]
      end
    end

    def find_instance
      ::Family.find(@transcript[:source]['_id'])
    end

    # def find_or_create_person(person)
    #   matches = match_person_instance(person)
    #   # if matches.blank?
    #   #   Person.create(person.attributes.except('_id', 'version', 'updated_at', 'created_at', 'updated_by_id'))
    #   if matches.size > 1
    #     raise AmbiguousMatchError, "Duplicate person matches found while building family member"
    #   else
    #     matches.first
    #   end
    # end

    def create_new_family
      @updates[:new] ||= {}
      @updates[:new][:new] ||= {}

      @updates[:new][:new]['e_case_id'] = ["Ignored", "Ignored per Family update rule set."]

      # begin
      #   primary = @other_family.primary_applicant
      #   primary_person = match_person_instance(primary.person)

      #   if primary_person.primary_family.present?
      #     raise StaleRecordError, "Family recrod created on #{matches.first.primary_family.created_at.strftime('%m/%d/%Y')} after transcript generated"
      #   end

      #   family = Family.new({
      #     hbx_assigned_id: @other_family.hbx_assigned_id,
      #     e_case_id: @other_family.e_case_id
      #     })

      #   @other_family.family_members.each do |family_member|
      #     matched_person = match_person_instance(family_member.person)
      #     family.add_family_member(matched_person, is_primary_applicant: family_member.is_primary_applicant)
      #     relationship = (family_member.is_primary_applicant ? 'self' : family_member.person.person_relationships.first.try(:kind).to_s)
      #     family.relate_new_member(matched_person, relationship)
      #   end

      #   family.save!
      #   @updates[:new][:new]['ssn'] = ["Success", "Created new family record"]

      # rescue Exception => e 
      #   @updates[:new][:new]['e_case_id'] = ["Failed", "#{e.inspect}"]
      # end
    end

    def add_family_members(attributes)
      if @family.family_members.detect{|fm| fm.hbx_id == attributes['hbx_id']}
        raise AmbiguousMatchError, "Family member already exists with given hbx_id."
      end

      matched_people = ::Person.where(hbx_id: attributes['hbx_id'])

      if matched_people.blank?
        raise PersonNotFound, "Person not found with given family member hbx_id."
      end

      if matched_people.size > 1
        raise AmbiguousMatchError, "Ambiguous primary matches found."
      end

      matched_person = matched_people.first
      @family.add_family_member(matched_person, is_primary_applicant: attributes['is_primary_applicant'])
      @family.relate_new_member(matched_person, attributes['relationship'])
      @family.save!
    end

    def add_irs_groups(attributes)
    end

    def match_person_instance(person)
      # if person.hbx_id.present?
      matched_people = ::Person.where(hbx_id: person.hbx_id) || []
      # else
      #   matched_people = ::Person.match_by_id_info(
      #       ssn: person.ssn,
      #       dob: person.dob,
      #       last_name: person.last_name,
      #       first_name: person.first_name
      #     )
      # end

      if matched_people.blank?
        raise PersonNotFound, "Person record not found."
      end

      if matched_people.size > 1
        raise AmbiguousMatchError, "Ambiguous primary matches found."
      end

      matched_people.first
    end

    def validate_timestamp(section)
      if section == :base
        if @family.updated_at.to_date > @transcript[:source]['updated_at'].to_date
          raise StaleRecordError, "Change set unprocessed, source record updated after Transcript generated. Updated on #{@family.updated_at.strftime('%m/%d/%Y')}"
        end
      else
        transcript_record = @transcript[:source][section.to_s].sort_by{|x| x['updated_at']}.reverse.first if @transcript[:source][section.to_s].present?
        source_record = @family.send(section).sort_by{|x| x.updated_at}.reverse.first if @family.send(section).present?
        return if transcript_record.blank? || source_record.blank?

        if source_record.updated_at.to_date > transcript_record['updated_at'].to_date
          raise StaleRecordError, "Change set unprocessed, source record updated after Transcript generated. Updated on #{source_record.updated_at.strftime('%m/%d/%Y')}"
        end
      end
    end
  end
end