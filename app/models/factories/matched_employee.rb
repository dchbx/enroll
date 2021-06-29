# frozen_string_literal: true

module Factories
  class MatchedEmployee
    def build(consumer_identity, roster_employee, person)
      person_form = person
      unless person_form
        person_form = Person.new({
                                   :date_of_birth => consumer_identity.date_of_birth,
                                   :ssn => consumer_identity.ssn
                                 })
        build_address_from_employee(person_form, roster_employee)
      end
      person_form.user_id = consumer_identity.user_id
      populate_identity_properties(person_form, consumer_identity)
      build_nested_models(person_form)
      build_employee_role_and_assign(person_form, roster_employee)
    end

    def populate_identity_properties(person, ci)
      copy_properties(
        ci,
        person,
        [:first_name, :last_name, :middle_name, :name_pfx, :name_sfx, :gender]
      )
    end

    def copy_properties(from, to, props)
      props.each do |prop|
        copy_property(from, to, prop)
      end
    end

    def copy_property(from, to, prop)
      to.send("#{prop}=", from.send(prop))
    end

    def build_nested_models(person)
      ["home","mobile","work","fax"].each do |kind|
        person.phones.build(kind: kind) if person.phones.select{|phone| phone.kind == kind}.blank?
      end

      Address::KINDS.each do |kind|
        person.addresses.build(kind: kind) if person.addresses.select{|address| address.kind == kind}.blank?
      end

      ["home","work"].each do |kind|
        person.emails.build(kind: kind) if person.emails.select{|email| email.kind == kind}.blank?
      end
    end

    def build_employee_role_and_assign(person, census_employee)
      emp_family = census_employee.employee_family
      person_wrapper = Forms::EmployeeRole.new(person)
      person_wrapper.hired_on = census_employee.hired_on
      person_wrapper.terminated_on = census_employee.terminated_on
      person_wrapper.benefit_group_id = emp_family.benefit_group_id
      person_wrapper.employer_profile_id = emp_family.employer_profile.id
      person_wrapper.organization_id = emp_family.employer_profile.organization.id
      person_wrapper.census_employee_id = census_employee.id
      person_wrapper
    end

    def build_address_from_employee(person_form, census_employee)
      if census_employee.address.present?
        # Because it hates us so much, mongoid will copy over all of the
        # attributes unless we tell it don't do that.
        ca = census_employee.address
        person_form.address.new({
                                  :address_1 => ca.address_1,
                                  :address_2 => ca.address_2,
                                  :city => ca.city,
                                  :state => ca.state,
                                  :zip => ca.zip
                                })
      end
    end
  end
end
