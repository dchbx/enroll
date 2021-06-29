# frozen_string_literal: true

module Factories
  class EmployeeSignup
    def build(consumer_identity, roster_employee, person)
      employee_signup_form = ::Forms::EmployeeSignup({
                                                       :employee_id => roster_employee.id,
                                                       :date_of_birth => consumer_identity.date_of_birth,
                                                       :ssn => consumer_identity.ssn,
                                                       :user_id => consumer_identity.user_id
                                                     })
      if person.blank?
        populate_identity_properties(employee_signup_form, consumer_identity)
      else
        populate_person_properties(employee_signup_form, person)
      end
      employee_signup_form
    end

    def populate_identity_properties(form, ci)
      copy_properties(
        ci,
        form,
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

    def populate_person_properties(form, person)
      form.person_id = person.id
      copy_properties(
        person,
        form,
        [:first_name, :last_name, :middle_name, :name_pfx, :name_sfx, :gender]
      )
      copy_addresses(form, person)
      copy_phones(form, person)
      copy_emails(form, person)
    end

    def copy_addresses(form, person)
      addresses = []
      person.addresses.each do |addy|
        address = ::Forms::Address.new
        copy_properties(addy, address, [:kind, :address_1, :address_2, :state, :city, :zip])
        addressess << address
      end
      form.addresses = addresses
    end

    def copy_phones(form, person); end

    def copy_emails(form, person); end
  end
end
