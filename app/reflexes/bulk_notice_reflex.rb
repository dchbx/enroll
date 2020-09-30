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
      org_attrs = cache_or_fetch_org_attrs(identifier)
<<<<<<< HEAD
      if badges.include?(identifier) # already has a badge for this identifier
        badges
      elsif org_attrs.key?(:error)
        badges + ApplicationController.render(partial: "exchanges/bulk_notices/recipient_error_badge", locals: { id: identifier, error: org_attrs[:error], hbx_id: org_attrs[:hbx_id] })
      elsif org_attrs[:types].include?(audience_type)
        badges + ApplicationController.render(partial: "exchanges/bulk_notices/recipient_badge", locals: { id: org_attrs[:id], hbx_id: org_attrs[:hbx_id] })
      else
        badges + ApplicationController.render(partial: "exchanges/bulk_notices/recipient_error_badge", locals: { id: org_attrs[:id], error: 'Wrong audience type', hbx_id: org_attrs[:hbx_id] })
=======
      return badges if badges.include?(identifier)
      if org_attrs.key?(:error)
        badges + ApplicationController.render(partial: "exchanges/bulk_notices/recipient_error_badge", locals: { id: identifier, error: org_attrs[:error], legal_name: org_attrs[:legal_name] })
      elsif org_attrs[:types].include?(audience_type)
        badges + ApplicationController.render(partial: "exchanges/bulk_notices/recipient_badge", locals: { id: org_attrs[:id], legal_name: org_attrs[:legal_name] })
      else
        badges + ApplicationController.render(partial: "exchanges/bulk_notices/recipient_error_badge", locals: { id: org_attrs[:id], error: 'Wrong audience type', legal_name: org_attrs[:legal_name] })
>>>>>>> e9f7af3894... Work in Progress.
      end
    end
  end

  def cache_or_fetch_org_attrs(org_identifier)
    # this method accepts an org_identifier, which it uses to check for an existing cache or fetch the missing org with the given
<<<<<<< HEAD
    # identifier, which should be either a FEIN, Id or an HBX id
=======
    # identifier, which should be either a FEIN or an HBX id
>>>>>>> e9f7af3894... Work in Progress.
    session[:bulk_notice] ||= { audience: {} }
    return session[:bulk_notice][:audience][org_identifier] if session[:bulk_notice][:audience].key?(org_identifier)

    organization = BenefitSponsors::Organizations::Organization.where(fein: org_identifier).first ||
<<<<<<< HEAD
                   BenefitSponsors::Organizations::Organization.where(hbx_id: org_identifier).first ||
                   BenefitSponsors::Organizations::Organization.where(id: org_identifier).first
=======
                   BenefitSponsors::Organizations::Organization.where(hbx_id: org_identifier).first
>>>>>>> e9f7af3894... Work in Progress.
    if organization
      session[:bulk_notice][:audience][organization.id.to_s] = { id: organization.id,
                                                                 legal_name: organization.legal_name,
                                                                 fein: organization.fein,
                                                                 hbx_id: organization.hbx_id,
                                                                 types: organization.profile_types }
    else
      session[:bulk_notice][:audience][org_identifier] = { id: org_identifier, error: 'Not found' }
    end
  end
end
