# frozen_string_literal: true

module Employers
  class PeopleController < ApplicationController
    include ResourceConfigurator

    before_action :check_person_present, only: [:search]

    def search
      @person = Forms::EmployeeCandidate.new
      respond_to do |format|
        format.html
        format.js
      end
    end

    def match
      @employee_candidate = Forms::EmployeeCandidate.new(person_params.merge({user_id: current_user.id}))
      if @employee_candidate.valid?
        found_person = @employee_candidate.match_person
        if params["create_person"].present? # when create person button clicked
          @person = current_user.instantiate_person
          @person.attributes = params.permit(person_params)
          @person.save
          build_nested_models
          respond_to do |format|
            format.js { render "edit" }
            format.html { render "edit" }
          end
        elsif found_person.present? # when search button is clicked
          @person = found_person
          respond_to do |format|
            format.js { render 'match' }
            format.html { render 'match' }
          end
        else # when there is no person match
          @person = Person.new
          build_nested_models
          respond_to do |format|
            format.js { render 'no_match' }
            format.html { render 'no_match' }
          end
        end
      else # when person is not valid
        @person = @employee_candidate
        respond_to do |format|
          format.js { render 'search' }
          format.html { render 'search' }
        end
      end
    end

    def create
      @person = current_user.person
      build_nested_models
      respond_to do |format|
        format.js { render "edit" }
        format.html { render "edit" }
      end
    end

    def update
      sanitize_person_params
      @person = Person.find(params[:id])
      make_new_person_params @person

      @employer_profile = @person.employer_contact.present? ? @person.employer_contact : @person.build_employer_contact
      @person.updated_by = current_user.oim_id if current_user.present?

      respond_to do |format|
        if @person.update_attributes(params[:person])
          format.js { render "employer_form" }
          format.html { render "employer_form" }
        else
          build_nested_models
          format.html { render action: "show" }
          format.json { render json: @person.errors, status: :unprocessable_entity }
        end
      end
    end

    private

    def person_params
      params.require(:person).permit(:first_name, :user_id)
    end

    def build_nested_models
      ["home","mobile","work","fax"].each do |kind|
        @person.phones.build(kind: kind) if @person.phones.select{|phone| phone.kind == kind}.blank?
      end

      Address::KINDS.each do |kind|
        @person.addresses.build(kind: kind) if @person.addresses.select{|address| address.kind == kind}.blank?
      end

      ["home","work"].each do |kind|
        @person.emails.build(kind: kind) if @person.emails.select{|email| email.kind == kind}.blank?
      end
    end

    def sanitize_person_params
      person_params["addresses_attributes"].each do |key, address|
        person_params["addresses_attributes"].delete(key.to_s) if address["city"].blank? && address["zip"].blank? && address["address_1"].blank?
      end

      person_params["phones_attributes"].each do |key, phone|
        person_params["phones_attributes"].delete(key.to_s) if phone["full_phone_number"].blank?
      end

      person_params["emails_attributes"].each do |key, email|
        person_params["emails_attributes"].delete(key.to_s) if email["address"].blank?
      end
    end

    def make_new_person_params(person)
      # Delete old sub documents
      person.addresses.each(&:delete)
      person.phones.each(&:delete)
      person.emails.each(&:delete)

      person_params["addresses_attributes"].each do |_key, address|
        address.delete('id') if address.key?('id')
      end

      person_params["phones_attributes"].each do |_key, phone|
        phone.delete('id') if phone.key?('id')
      end

      person_params["emails_attributes"].each do |_key, email|
        email.delete('id') if email.key?('id')
      end
    end

    def person_params
      params.require(:person).permit(*person_parameters_list)
    end

    def person_parameters_list
      [
        { :addresses_attributes => [:kind, :address_1, :address_2, :city, :state, :zip, :id, :_destroy] },
        { :phones_attributes => [:kind, :full_phone_number, :id, :_destroy] },
        { :emails_attributes => [:kind, :address, :id, :_destroy] },
        { :consumer_role_attributes => [:contact_method, :language_preference, :id]},
        { :employee_roles_attributes => [:id, :contact_method, :language_preference]},

        :first_name,
        :middle_name,
        :last_name,
        :name_sfx,
        :gender,
        :us_citizen,
        :is_incarcerated,
        :language_code,
        :is_disabled,
        :race,
        :is_consumer_role,
        :is_resident_role,
        :naturalized_citizen,
        :eligible_immigration_status,
        :indian_tribe_member,
        {:ethnicity => []},
        :tribal_id,
        :no_dc_address,
        :is_homeless,
        :is_temporarily_out_of_state,
        :id,
        :consumer_role,
        :is_applying_coverage
      ]
    end

    def check_person_present
      if current_user.person.present?
        @employer_profile = Forms::EmployerCandidate.new
        respond_to do |format|
          format.js { render "employers/employer_profiles/search"}
          format.html {}
        end
      end
    end

  end
end
