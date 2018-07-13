module Importers
  class ConversionEmployeeCreate < ConversionEmployeeCommon

    validate :validate_fein
    validate :validate_relationships
    validates_length_of :fein, is: 9

    def validate_relationships
      (1..8).to_a.each do |num|
        dep_ln = "dep_#{num}_name_last".to_sym
        dep_rel = "dep_#{num}_relationship".to_sym
        unless self.send(dep_ln).blank?
          if self.send(dep_rel).blank?
            errors.add("dep_#{num}_relationship", "invalid.  must be one of: #{RELATIONSHIP_MAP.keys.join(", ")}")
          end
        end
      end
    end

    def map_subscriber
      last_name = subscriber_name_last
      first_name = subscriber_name_first
      middle_name = subscriber_name_middle
      dob = subscriber_dob
      gender = subscriber_gender
      ssn = subscriber_ssn
      email = subscriber_email
      address_1 = subscriber_address_1
      address_2 = subscriber_address_2
      city = subscriber_city
      state = subscriber_state
      zip = subscriber_zip
      attr_hash = {
          first_name: first_name,
          last_name: last_name,
          dob: dob,
          gender: gender
      }
      if hire_date.blank?
        attr_hash[:hired_on] = default_hire_date
      else
        attr_hash[:hired_on] = hire_date
      end
      unless middle_name.blank?
        attr_hash[:middle_name] = middle_name
      end
      unless ssn.blank?
        attr_hash[:ssn] = ssn
      end
      unless email.blank?
        attr_hash[:email] = Email.new(:kind => "work", :address => email)
      end
      unless address_1.blank?
        addy_attr = {
            kind: "home",
            city: city,
            state: state,
            address_1: address_1,
            zip: zip
        }
        unless address_2.blank?
          addy_attr[:address_2] = address_2
        end
        attr_hash[:address] = Address.new(addy_attr)
      end
      CensusEmployee.new(attr_hash)
    end

    def map_dependent(dep_idx)
      last_name = self.send("dep_#{dep_idx}_name_last".to_sym)
      first_name = self.send("dep_#{dep_idx}_name_first".to_sym)
      middle_name = self.send("dep_#{dep_idx}_name_middle".to_sym)
      relationship = self.send("dep_#{dep_idx}_relationship".to_sym)
      dob = self.send("dep_#{dep_idx}_dob".to_sym)
      ssn = self.send("dep_#{dep_idx}_ssn".to_sym)
      gender = self.send("dep_#{dep_idx}_gender".to_sym)
      if [first_name, last_name, middle_name, relationship, dob, ssn, gender].all?(&:blank?)
        return nil
      end
      attr_hash = {
          first_name: first_name,
          last_name: last_name,
          dob: dob,
          employee_relationship: relationship,
          gender: gender
      }
      unless middle_name.blank?
        attr_hash[:middle_name] = middle_name
      end
      unless ssn.blank?
        if ssn == subscriber_ssn
          warnings.add("dependent_#{dep_idx}_ssn", "ssn same as subscriber, blanking for import")
        else
          attr_hash[:ssn] = ssn
        end
      end
      CensusDependent.new(attr_hash)
    end

    def map_dependents
      (1..8).to_a.map do |idx|
        map_dependent(idx)
      end.compact
    end

    def validate_fein
      return true if fein.blank?
      found_employer = find_employer
      if found_employer.nil?
        errors.add(:fein, "does not exist")
      end
    end

    def find_employer
      org = Organization.where(:fein => fein).first
      return nil unless org
      org.employer_profile
    end

    def save
      return false unless valid?
      census_employee = map_subscriber
      census_employee.employer_profile = find_employer
      census_employee.census_dependents = map_dependents
      save_result = census_employee.save
      unless save_result
        propagate_errors(census_employee)
      end
      return save_result
    end

    def propagate_errors(census_employee)
      census_employee.errors.each do |attr, err|
        errors.add("census_employee_" + attr.to_s, err)
      end
      census_employee.census_dependents.each_with_index do |c_dep, idx|
        c_dep.errors.each do |attr, err|
          errors.add("dependent_#{idx}_" + attr.to_s, err)
        end
      end
    end
  end
end