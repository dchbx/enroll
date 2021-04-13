# frozen_string_literal: true

module ManageAccount
  # To find out Personal information fields with ID, class attrs for cucumbers POM.
  class PersonalInformation

    def self.first_name
      'person[first_name]'
    end

    def self.middle_name
      'person[middle_name]'
    end

    def self.last_name
      'person[last_name]'
    end

    def self.suffix_dropdown
      'person_name_sfx'
    end

    def self.dob
      'person[dob]'
    end

    def self.social_security
      'person[ssn]'
    end

    def self.gender
      'person_gender'
    end

    def self.update_person
      '#save-person'
    end

    def self.personal_information_form
      ".personal_information_form"
    end

    def self.success_message
      'Person successfully updated.'
    end
  end
end
