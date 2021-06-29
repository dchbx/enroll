# frozen_string_literal: true

module Exchanges
  class BrokerApplicantsController < ApplicationController
    include Exchanges::BrokerApplicantsHelper
    layout 'single_column'

    before_action :check_hbx_staff_role
    before_action :find_broker_applicant, only: [:edit, :update]

    def index
      @people = Person.broker_role_having_agency

      status_params = params.permit(:status)
      @status = BrokerRole::BROKER_ROLE_STATUS_TYPES.include?(status_params[:status]) ? status_params[:status] : 'applicant'
      @people = @people.send("broker_role_#{@status}") if @people.respond_to?("broker_role_#{@status}")
      @page_alphabets = page_alphabets(@people, "last_name")

      if params[:page].present?
        page_no = cur_page_no(@page_alphabets.first)
        @broker_applicants = @people.where("last_name" => /^#{Regexp.escape(page_no)}/i)
      else
        @broker_applicants = sort_by_latest_transition_time(@people).limit(20).entries
      end

      respond_to do |format|
        format.html { render "shared/brokers/applicants.html.slim" }
        format.js
      end
    end

    def edit
      respond_to do |format|
        format.html { render "shared/brokers/applicant.html.erb" }
      end
    end

    def update
      broker_role = @broker_applicant.broker_role
      broker_role.update_attributes(reason: params.require(:person).require(:broker_role_attributes).permit(:reason)) if params.dig(:person, :broker_role_attributes, :reason).present?
      # TODO: This params['deny'] stuff might have to be changed to params['commit']['action_name']
      if params['deny']
        broker_role.deny!
        flash[:notice] = "Broker applicant denied."
      elsif params['update']
        if broker_role.update!(broker_role_update_params)
          flash[:notice] = "Broker applicant successfully updated."
        else
          flash[:error] = "Unable to update broker applicant."
        end
      elsif params['decertify']
        broker_role.decertify!
        flash[:notice] = "Broker applicant decertified."
      elsif params['recertify']
        broker_role.recertify!
        flash[:notice] = "Broker applicant is now approved."
      elsif params['extend']
        broker_role.extend_application!
        flash[:notice] = "Broker applicant is now extended."
      elsif params['pending']
        broker_carrier_appointments
        broker_role.update(params.require(:person).require(:broker_role_attributes).permit(:training, :license, :carrier_appointments => {}).except(:id))
        broker_role.pending!
        flash[:notice] = "Broker applicant is now pending."
      else
        broker_carrier_appointments
        broker_role.update(params.require(:person).require(:broker_role_attributes).permit(:training, :license, :carrier_appointments => {}).except(:id))
        broker_role.approve!
        broker_role.reload

        if broker_role.is_primary_broker?
          broker_role.broker_agency_profile.approve! if broker_role.broker_agency_profile.aasm_state != "is_approved"
          staff_role = broker_role.person.broker_agency_staff_roles[0]
          staff_role&.broker_agency_accept!
        end

        send_secure_message_to_broker_agency(broker_role) if broker_role.agency_pending? && broker_role.broker_agency_profile
        flash[:notice] = "Broker applicant approved successfully."
      end

      redirect_to "/exchanges/hbx_profiles"
    end

    private

    def broker_role_update_params
      # Only assign if nil
      params[:person][:broker_role_attributes][:carrier_appointments] ||= {}
      params[:person][:broker_role_attributes].permit(:license, :training, :carrier_appointments => {})
    end

    def broker_carrier_appointments
      all_carrier_appointments = EnrollRegistry[:brokers].setting(:carrier_appointments).item.stringify_keys
      broker_carrier_appointments_enabled = Settings.aca.broker_carrier_appointments_enabled
      if broker_carrier_appointments_enabled
        params[:person][:broker_role_attributes][:carrier_appointments] = all_carrier_appointments.each{ |key,_str| all_carrier_appointments[key] = "true" }
      else
        # Fix this
        permitted_params = params.require(:person).require(:broker_role_attributes).permit(:carrier_appointments => {}).to_h
        all_carrier_appointments.merge!(permitted_params[:carrier_appointments]) if permitted_params[:carrier_appointments]
        params[:person][:broker_role_attributes][:carrier_appointments] = all_carrier_appointments
      end
    end

    def send_secure_message_to_broker_agency(broker_role)
      hbx_admin = HbxProfile.all.first
      broker_agency = broker_role.broker_agency_profile

      subject = "Received new broker application - #{broker_role.person.full_name}"
      body = "<br><p>Following are broker details<br>Broker Name : #{broker_role.person.full_name}<br>Broker NPN  : #{broker_role.npn}</p>"
      secure_message(hbx_admin, broker_agency, subject, body)
    end

    def find_broker_applicant
      @broker_applicant = Person.find(BSON::ObjectId.from_string(params[:id]))
    end

    def check_hbx_staff_role
      redirect_to exchanges_hbx_profiles_root_path, :flash => { :error => "You must be an HBX staff member" } unless current_user.has_hbx_staff_role?
    end
  end
end
