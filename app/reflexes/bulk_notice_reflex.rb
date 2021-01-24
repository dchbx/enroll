# frozen_string_literal: true

# Class to hold reflex methods
class BulkNoticeReflex < ApplicationReflex
  # Add Reflex methods in this file.
  #
  # All Reflex instances expose the following properties:
  #
  #   - connection - the ActionCable connection
  #   - channel - the ActionCable channel
  #   - request - an ActionDispatch::Request proxy for the socket connection
  #   - session - the ActionDispatch::Session store for the current visitor
  #   - url - the URL of the page that triggered the reflex
  #   - element - a Hash like object that represents the HTML element that triggered the reflex
  #   - params - parameters from the element's closest form (if any)
  #
  # Example:
  #
  #   def example(argument=true)
  #     # Your logic here...
  #     # Any declared instance variables will be made available to the Rails controller and view.
  #   end
  #
  # Learn more at: https://docs.stimulusreflex.com
  def new_identifier
    # this method adds splits the new identifiers, adds them to the existing audience_ids already on the page
    # and then loops through all the audience_ids to generate badges
    # employee becomes employer, every other type as is
    audience_type = params[:admin_bulk_notice][:audience_type] == 'employee' ? 'employer' : params[:admin_bulk_notice][:audience_type]
    audience_ids = params[:admin_bulk_notice][:audience_ids] || []

    identifiers = element[:value]
    morph '#recipient-list', org_badges_for(identifiers.split(/\s| |, |,/m) + audience_ids, audience_type)
  end

  def audience_select
    # this method loops through the existing audience_ids already on the page to generate badges,
    # which does audience type checks
    # employee becomes employer, every other type as is
    audience_type = params[:admin_bulk_notice][:audience_type] == 'employee' ? 'employer' : params[:admin_bulk_notice][:audience_type]
    audience_ids = params[:admin_bulk_notice][:audience_ids] || []

    morph '#recipient-list', org_badges_for(audience_ids, audience_type)
  end

  def org_badges_for(audience_ids, audience_type)
    # this method loops through the given audience_ids and displays a normal badge or error badge if the types are wrong
    audience_ids.reduce('') do |badges, identifier|
      org_attrs = cache_or_fetch_entity_attrs(identifier)
      if badges.include?(identifier) # already has a badge for this identifier
        badges
      elsif org_attrs.key?(:error)
        badges + ApplicationController.render(partial: "exchanges/bulk_notices/recipient_error_badge", locals: { id: identifier, error: org_attrs[:error], hbx_id: org_attrs[:hbx_id] })
      elsif org_attrs[:types].include?(audience_type)
        badges + ApplicationController.render(partial: "exchanges/bulk_notices/recipient_badge", locals: { id: org_attrs[:id], hbx_id: org_attrs[:hbx_id] })
      else
        badges + ApplicationController.render(partial: "exchanges/bulk_notices/recipient_error_badge", locals: { id: org_attrs[:id], error: 'Wrong audience type', hbx_id: org_attrs[:hbx_id] })
      end
    end
  end

  def cache_or_fetch_entity_attrs(entity_identifier) # rubocop:disable Metrics/AbcSize
    # this method accepts an org_identifier, which it uses to check for an existing cache or fetch the missing org with the given
    # identifier, which should be either a FEIN, Id or an HBX id
    session[:bulk_notice] ||= { audience: {} }
    return session[:bulk_notice][:audience][entity_identifier] if session[:bulk_notice][:audience].key?(entity_identifier)

    organization = BenefitSponsors::Organizations::Organization.where(fein: entity_identifier).first ||
                   BenefitSponsors::Organizations::Organization.where(hbx_id: entity_identifier).first ||
                   BenefitSponsors::Organizations::Organization.where(id: entity_identifier).first
    consumer = Person.all_consumer_roles.by_hbx_id(entity_identifier).first
    resident = Person.all_resident_roles.by_hbx_id(entity_identifier).first
    employee = Person.all_employee_roles.by_hbx_id(entity_identifier).first

    if organization
      session[:bulk_notice][:audience][organization.id.to_s] = { id: organization.id,
                                                                 legal_name: organization.legal_name,
                                                                 fein: organization.fein,
                                                                 hbx_id: organization.hbx_id,
                                                                 types: organization.profile_types }
    elsif consumer
      session[:bulk_notice][:audience][consumer.id.to_s] = { id: consumer.id,
                                                             legal_name: consumer.full_name,
                                                             fein: "",
                                                             hbx_id: consumer.hbx_id,
                                                             types: 'consumer' }
    elsif resident
      session[:bulk_notice][:audience][resident.id.to_s] = { id: resident.id,
                                                             legal_name: resident.full_name,
                                                             fein: "",
                                                             hbx_id: resident.hbx_id,
                                                             types: 'resident' }
    else
      session[:bulk_notice][:audience][entity_identifier] = { id: entity_identifier, error: 'Not found' }
    end
  end
end
