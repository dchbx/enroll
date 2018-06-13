class UserMailer < ApplicationMailer
  ### add_template_helper makes the view helper methods available in the Mailer templates. It does NOT make the methods available in the Mailer itself
  ### Thus we have to use Include in addition to add_template_helper
  add_template_helper Config::AcaHelper
  add_template_helper Config::SiteHelper
  add_template_helper Config::ContactCenterHelper
  include Config::AcaHelper
  include Config::SiteHelper
  include Config::ContactCenterHelper

  def welcome(user)
    if user.email.present?
      mail({to: user.email, subject: "Thank you for registering."}) do |format|
        format.text
      end
    end
  end

  def plan_shopping_completed(user, hbx_enrollment, plan_decorator)
    if user.email.present?
      mail({to: user.email, subject: "Your #{site_short_name} Enrollment Confirmation"}) do |format|
        format.html { render "plan_shopping_completed", :locals => { :user => user, :enrollment => hbx_enrollment, :plan => plan_decorator } }
      end
    end
  end

  def invitation_email(email, person_name, invitation)
    if email.present?
      mail({to: email, subject: "Invitation from your Employer to Sign up for Health Insurance at #{site_short_name} "}) do |format|
        format.html { render "invitation_email", :locals => { :person_name => person_name, :invitation => invitation }}
      end
    end
  end

  #Email will sent to census employees as soon as they are added to the roster
  def send_employee_open_enrollment_invitation(email, census_employee, invitation)
    plan_years = census_employee.employer_profile.plan_years.published_or_renewing_published.select{|py| py.coverage_period_contains?(census_employee.earliest_effective_date)}
    if email.present? && plan_years.any?{|py| py.employees_are_matchable?}
      if (census_employee.hired_on > TimeKeeper.date_of_record)
        mail({to: email, subject: "You Have Been Invited to Sign Up for Employer-Sponsored Coverage through the #{Settings.site.long_name}"}) do |format|
          format.html { render "invite_future_employee_for_open_enrollment", :locals => { :census_employee => census_employee, :invitation => invitation }}
        end
      else
        mail({to: email, subject: "Enroll Now: Your Health Plan Open Enrollment Period has Begun"}) do |format|
          format.html { render "invite_initial_employee_for_open_enrollment", :locals => { :census_employee => census_employee, :invitation => invitation }}
        end
      end
    end
  end

  #Email will be sent to census employees when they reach the DOH.
  def send_future_employee_open_enrollment_invitation(email, census_employee, invitation)
    plan_years = census_employee.employer_profile.plan_years.published_or_renewing_published.select{|py| py.coverage_period_contains?(census_employee.earliest_effective_date)}
    if email.present? && plan_years.any?{|py| py.employees_are_matchable?}
      mail({to: email, subject: "Enroll Now: Your Health Plan Open Enrollment Period has Begun"}) do |format|
        format.html { render "invite_initial_employee_for_open_enrollment", :locals => { :census_employee => census_employee, :invitation => invitation }}
      end
    end
  end

  def renewal_invitation_email(email, census_employee, invitation)
    mail({to: email, subject: "Enroll Now: Your Health Plan Open Enrollment Period has Begun"}) do |format|
      format.html { render "renewal_invitation_email", :locals => { :census_employee => census_employee, :invitation => invitation }}
    end
  end

  def initial_employee_invitation_email(email, census_employee, invitation)
    mail({to: email, subject: "Enroll Now: Your Health Plan Open Enrollment Period has Begun"}) do |format|
      format.html { render "initial_employee_invitation_email", :locals => { :census_employee => census_employee, :invitation => invitation }}
    end
  end

  def agent_invitation_email(email, person_name, invitation)
    if email.present?
      mail({to: email, subject: "#{site_short_name} Support Invitation"}) do |format|
        format.html { render "agent_invitation_email", :locals => { :person_name => person_name, :invitation => invitation }}
      end
    end
  end

  def broker_invitation_email(email, person_name, invitation)
    if email.present?
      mail({to: email, subject: "Congratulations! Your Broker Application for the #{site_short_name} for Business has been Approved!"}) do |format|
        format.html { render "broker_invitation_email", :locals => { :person_name => person_name, :invitation => invitation }}
      end
    end
  end

  def message_to_broker(person, broker, params)
    if broker.email_address.present?
      mail({to: broker.email_address, subject: params[:subject], from: person.user.email}) do |format|
        format.html { render "message_to_broker", :locals => { :person => person, :broker => broker, :message_body => params[:body] }}
      end
    end
  end

  def send_employee_ineligibility_notice(email, first_name)
    if email.present?
      message = mail({to: email, subject: "#{Settings.site.short_name} - Assistance Enrolling in Employer-sponsored Health Insurance", from: '#{mail_address}'}) do |format|
        format.html {render "employee_ineligibility_notice", locals: {first_name: first_name}}
      end
    end
  end

  def new_client_notification(agent_email, first_name, name, role, insured_email, is_person)
    if agent_email.present?
      subject = "New Client Notification -[#{name}] email provided - [#{insured_email}]"
      mail({to: agent_email, subject: subject, from: "no-reply@individual.#{site_domain_name}"}) do |format|
        format.html { render "new_client_notification", :locals => { first_name: first_name, :role => role, name: name}}
      end
    end
  end

  def generic_consumer_welcome(first_name, hbx_id, email)
    if email.present?
      mail({to: email, subject: site_short_name, from: "no-reply@individual.#{site_domain_name}"}) do |format|
        format.html {render "generic_consumer", locals: {first_name: first_name, hbx_id: hbx_id}}
      end
    end
  end


  def generic_notice_alert(first_name, notice_subject, email, files_to_attach={})
    files_to_attach.each do |file_name, file_path|
      attachments["#{file_name}"] = File.read(file_path)
    end
    message =  mail({to: email, subject: "You have a new message from #{site_short_name}", from: "no-reply@individual.#{site_domain_name}"}) do |format|
      format.html {render "generic_notice_alert", locals: {first_name: first_name, notice_subject: notice_subject}}
    end
  end


  # def generic_notice_alert_to_ba_and_ga(first_name, email, employer_name)
  #   if email.present?
  #     message = mail({to: email, subject: "You have a new message from DC Health Link", from: 'no-reply@individual.dchealthlink.com'}) do |format|
  #       format.html {render "generic_notice_alert_to_broker_and_ga", locals: {first_name: first_name, employer_name: employer_name}}
  #     end
  #   end
  # end

  def generic_notice_alert_to_ba(first_name, email, employer_name)
    if email.present?
      message = mail({to: email, subject: "You have a new message from #{site_short_name}", from: '#{mail_address}'}) do |format|
       format.html {render "generic_notice_alert_to_broker", locals: {first_name: first_name, employer_name: employer_name}}
      end
    end
  end

  def employer_invoice_generation_notification(employer,subject)
    mail({to: employer.email, subject: subject, from: "no-reply@individual.#{site_domain_name}"}) do |format|
      format.html {render "employer_invoice_generation", locals: {first_name: employer.person.first_name}}
    end
  end

  def broker_denied_notification(broker_role)
    if broker_role.email_address.present?
      mail({to: broker_role.email_address, subject: "Broker application denied"}) do |format|
        format.html { render "broker_denied", :locals => { :applicant_name => broker_role.person.full_name }}
      end
    end
  end

  def broker_application_confirmation(person)
    if person.emails.find_by(kind: 'work').address.present?
      mail({to: person.emails.find_by(kind: 'work').try(:address) , subject: " Welcome! You've Submitted a Broker Application on the #{site_short_name} for Business"}) do |format|
        format.html { render "broker_application_confirmation", :locals => { :person => person }}
      end
    end
  end

  def broker_pending_notification(broker_role,unchecked_carriers)
    subject_sufix = unchecked_carriers.present? ? ", missing carrier appointments" : ", has all carrier appointments"
    subject_prefix = broker_role.training || broker_role.training == true ? "Action Needed - Broker License for #{site_short_name} for Business" : "Action Needed - Complete Broker Training for #{site_short_name} for Business"
    subject="#{subject_prefix}"
    mail({to: broker_role.email_address, subject: subject}) do |format|
      if broker_role.training && unchecked_carriers.present?
        format.html { render "broker_pending_completed_training_missing_carrier", :locals => { :applicant_name => broker_role.person.full_name ,:unchecked_carriers => unchecked_carriers}}
      elsif !broker_role.training && !unchecked_carriers.present?
        format.html { render "broker_pending_missing_training_completed_carrier", :locals => { :applicant_name => broker_role.person.full_name , :unchecked_carriers => unchecked_carriers}}
      elsif !broker_role.training && unchecked_carriers.present?
        format.html { render "broker_pending_missing_training_and_carrier", :locals => { :applicant_name => broker_role.person.full_name , :unchecked_carriers => unchecked_carriers}}
      end
    end
  end
end
