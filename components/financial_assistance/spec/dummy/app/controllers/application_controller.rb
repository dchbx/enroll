# frozen_string_literal: true

class ApplicationController < ActionController::Base
  helper FinancialAssistance::Engine.helpers

  def set_admin_bookmark_url(url = nil) # rubocop:disable Naming/AccessorMethodName
    set_current_person
    bookmark_url = url || request.original_url
    role = current_user.has_hbx_staff_role?
    @person.consumer_role.update_attributes(:admin_bookmark_url => bookmark_url) if !role.nil? && !prior_ridp_bookmark_urls(bookmark_url) && @person.has_consumer_role?
  end

  def save_faa_bookmark(person, url)
    return if person.consumer_role.blank?
    person.consumer_role.update_attribute(:bookmark_url, url) if person.consumer_role.identity_verified?
  end

  def set_current_person(required: true) # rubocop:disable Naming/AccessorMethodName
    @person = if current_user.try(:person).try(:agent?) && session[:person_id].present?
                Person.find(session[:person_id])
              else
                current_user.person
              end
    redirect_to logout_saml_index_path if required && !set_current_person_succeeded?
  end

  def set_current_person_succeeded?
    return true if @person
    message = {}
    message[:message] = 'Application Exception - person required'
    message[:session_person_id] = session[:person_id]
    message[:user_id] = current_user.id
    message[:oim_id] = current_user.oim_id
    message[:url] = request.original_url
    log(message, :severity => 'error')
    false
  end
end
