module Transcripts
  module Base

    # class MethodNotImplementedError < StandardError; end
    # raise MethodNotImplementedError, 'Please implement this method in your class.'

    def self.included(base)
      base.extend ClassMethods
    end

    def match_instance
      raise StandardError "Implement this method in child class"
    end

    def build_instance
      raise StandardError "Implement this method in child class"
    end

    module ClassMethods
      def associations
        @associations ||= []
      end

      def enumarated_associations
        @enumarated_associations ||= []
      end
    end

    def compare_instance
      return if @transcript[:other].blank?
      differences    = HashWithIndifferentAccess.new

      if @transcript[:source_is_new]
        differences[:new] = {:new => {:ssn => @transcript[:other].ssn}}
        @transcript[:compare] = differences
        return
      end

      differences[:base] = compare(base_record: @transcript[:source], compare_record: @transcript[:other])

      self.class.enumerated_associations.each do |association|
        differences[association[:association]] = build_association_differences(association)
      end

      @transcript[:compare] = differences
    end

    def build_association_differences(association)
      differences     = HashWithIndifferentAccess.new

      enumeration_association = association[:association]
      enumeration_field = association[:enumeration_field]      
      association_differences = []

      if association[:cardinality] == 'one'
        if association[:enumeration].blank?

          group_associations_by_enumeration_field(association).each do |association_pair|
            differences = compare_assocation(association_pair[0], association_pair[1], differences, enumeration_field)
          end
        else
          association[:enumeration].each do |attr_val|
            source = @transcript[:source].send(enumeration_association).detect{|assc| assc.send(association[:enumeration_field]) == attr_val }
            other  = @transcript[:other].send(enumeration_association).detect{|assc| assc.send(association[:enumeration_field]) == attr_val }

            differences = compare_assocation(source, other, differences, attr_val)
          end
        end
      end

      differences
    end

    def group_associations_by_enumeration_field(association)
      # TODO: Validate for duplicate family member records with same hbx id

      if association[:association] == 'hbx_enrollment_members'
        other_assocs = @transcript[:other].send(association[:association]).reject{|member| member.coverage_end_on.present? && member.coverage_end_on <= member.coverage_start_on}
      else
        other_assocs = @transcript[:other].send(association[:association]).to_a.dup
      end

      source_other_pairs = @transcript[:source].send(association[:association]).to_a.map do |source_assoc|
        enumeration_value = source_assoc.send(association[:enumeration_field])
        other_assoc = other_assocs.detect{|other_assoc| other_assoc.send(association[:enumeration_field]) == enumeration_value}
        other_assocs.delete(other_assoc)
        [source_assoc, other_assoc]
      end

      source_other_pairs + other_assocs.map { |other_assoc| [nil, other_assoc] }
    end

    def compare_assocation(source, other, differences, attr_val)
      assoc_class = (source || other).class.to_s
      if @custom_templates.include?(assoc_class)
        source = convert(source)
        other = convert(other)
      end

      if source.present? || other.present?
        if source.blank?
          if attr_val.to_s.match(/_id$/).present?
            identifer_val = other[attr_val.to_sym]
            key = "#{attr_val}:#{identifer_val}" if identifer_val.present?
          end
          differences[:add] ||= {}
          differences[:add][key || attr_val] = (other.is_a?(Hash) ? other : other.serializable_hash)
        elsif other.blank?
          if attr_val.to_s.match(/_id$/).present?
            identifer_val = source[attr_val.to_sym]
            key = "#{attr_val}:#{identifer_val}" if identifer_val.present?
          end
          differences[:remove] ||= {}
          differences[:remove][key || attr_val] = (source.is_a?(Hash) ? source : source.serializable_hash)
        elsif source.present? && other.present?
          if attr_val.to_s.match(/_id$/).present?
            identifer_val = source[attr_val.to_sym] || other[attr_val.to_sym]
            key = "#{attr_val}:#{identifer_val}" if identifer_val.present?
          end
          differences[:update] ||= {}
          differences[:update][key || attr_val] = compare(base_record: source, compare_record: other)
        end
      end
      differences
    end

    def compare(base_record:, compare_record:)
      differences     = HashWithIndifferentAccess.new

      if base_record.present? && compare_record.present?
        attribute_names = base_record.is_a?(Hash) ? base_record.keys : base_record.attribute_names

        all_keys = attribute_names.reject{|attr| @fields_to_ignore.include?(attr)}
        all_keys.each do |k|
          next if base_record[k].blank? && compare_record[k].blank?
     
          if base_record[k].blank?
            differences[:add] ||= {}
            differences[:add][k] = (compare_record[k].is_a?(Money) ? compare_record[k].to_f : compare_record[k])
          elsif compare_record[k].blank?
            differences[:remove] ||= {}
            differences[:remove][k] = (base_record[k].is_a?(Money) ? base_record[k].to_f : base_record[k])
          elsif base_record[k].is_a?(Array) && compare_record[k].is_a?(Array)
            differences[:array] ||= {}
            old_values = base_record[k] - compare_record[k]
            new_values = compare_record[k] - base_record[k]
            differences[:array][k] = { add: new_values, remove: old_values }.delete_if { |_, vv| vv.blank? }
            differences[:array][k].blank? ? differences = {} : differences[:array]
          else
            if base_record[k].is_a?(String) || compare_record[k].is_a?(String)
              base_attr = base_record[k].to_s.downcase.strip
              compare_attr = compare_record[k].to_s.downcase.strip
            else
              base_attr = (base_record.is_a?(Hash) ? base_record[k] : base_record.send(k))
              compare_attr = (compare_record.is_a?(Hash) ? compare_record[k] : compare_record.send(k))
            end

            if base_attr != compare_attr
              differences[:update] ||= {}
              differences[:update][k] = (compare_attr.is_a?(Money) ? compare_attr.to_f : compare_attr)
            end
          end
        end

        if attribute_names.include?('encrypted_ssn')
          if base_record.ssn.present?
            if compare_record.ssn.blank?
              differences[:remove] ||= {}
              differences[:remove][:ssn] = base_record.ssn
            elsif base_record.ssn != compare_record.ssn
              differences[:update] ||= {}
              differences[:update][:ssn] = compare_record.ssn
            end
          else
            differences[:add] ||= {}
            differences[:add][:ssn] = compare_record.ssn if compare_record.ssn.present?
          end
        end
      end

      differences
    end

    def validate_instance
      @transcript[:source].valid?
      @transcript[:other].valid?
      @transcript[:source_errors] = @transcript[:source].errors
      @transcript[:other_errors]  = @transcript[:other].errors
    end

    # Return model instance using the transcript hash table values
    def to_model
    end

    def copy_properties(from, to, properties)
      properties.each { |property| copy_property(from, to, property) }
    end

    def copy_property(from, to, property)
      to.send("#{property}=", from.send(property))
    end

    # Hash table for managing transcript factory data
    def transcript_template
      {
        # Local data set values
        source:         HashWithIndifferentAccess.new,
        # External data set values 
        other:          HashWithIndifferentAccess.new,
        # Result of comparing values of the "source" and "other" content
        compare:        HashWithIndifferentAccess.new,
        # Functional errors in the "source" data set
        source_errors:  HashWithIndifferentAccess.new,
        # Functional errors in the "other" data set
        other_errors:   HashWithIndifferentAccess.new,
        # "source" data set was generated from the "other" data set values?
        source_is_new:  false,
      }
    end

    def instance_with_all_attributes(class_name)
      klass.classify.constantize
      fields = klass.new.fields.inject({}){|data, (key, val)| data[key] = val.default_val; data }
      fields.delete_if{|key,_| @fields_to_ignore.include?(key)}
      klass.new(fields)
    end

    def family_transcript_prototype
      person = Person.new.fields.keys
      consumer_role = ConsumerRole.new.fields.keys
      person.consumer_role = consumer_role

      family = Family.new.fields.keys
      family.primary_family_member = person
      family.latest_household.hbx_enrollments << HbxEnrollment.new.fields.keys

      { family: family.attributes.merge({
        family_members: [
          family_member: family.family_members.first.attributes
          ],
          irs_groups: [
            irs_group: family.irs_groups.first.attributes
            ],
            households: [
              household: family.households.first.attributes.merge({
                hbx_enrollments: [
                  hbx_enrollment: family.households.first.hbx_enrollments.first.attributes
                ]
                })
            ]
            }),
      people: [
        person: person.attributes.merge({
          consumer_role: person.consumer_role.attributes
          })
        ] }
    end
  end
end
