module Operations
  class UpdateStaff
    attr_accessor :attrs

    def initialize(attrs={})
      @attrs = attrs
      @person_id = attrs[:person_id]
      sanitize_staff_params
    end

    def update_person
      begin
        return :matching_record_found if matched_people.present?
        return :information_missing unless has_required_keys?
        return :invalid_dob if dob_invalid?
        person.update_attributes(attrs)
        return :ok
      rescue Mongoid::Errors::DocumentNotFound
        :person_not_found
      rescue
        :error
      end
    end

    def update_email
      begin
        attrs[:emails].each do |record|
          begin
            email = person.emails.find(record[:id])
            email.assign_attributes(address: record[:address])
          rescue
            return :email_not_found
          end
        end

        return :ok if person.save
        :error
      rescue Mongoid::Errors::DocumentNotFound
        :person_not_found
      rescue
        :error
      end
    end

    def person
      return @person if defined? @person
      @person = Person.find(@person_id)
    end

    def matched_people
      Person.where(first_name: /^#{attrs[:first_name]}$/i, last_name: /^#{attrs[:last_name]}$/i, dob: attrs[:dob])
    end

    def sanitize_staff_params
      attrs.reject! {|key| attrs[key].blank? || key == 'person_id' }
      attrs[:dob] = Date.strptime(attrs[:dob], "%Y-%m-%d").to_date if attrs[:dob].present?
    end

    def has_required_keys?
      (attrs.keys.sort & required_keys) == required_keys
    end

    def dob_invalid?
      attrs[:dob] > (TimeKeeper.date_of_record - 18.years)
    end

    def policy_class
      AngularAdminApplicationPolicy
    end

    def required_keys
      ['first_name', 'last_name', 'dob'].sort
    end
  end
end
