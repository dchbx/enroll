class UserMailer < ApplicationMailer

  def welcome(user)
    if user.email.present?
      mail({to: user.email, subject: "Thank you for registering."}) do |format|
        format.text
      end
    end
  end

  def plan_shopping_completed(user, hbx_enrollment, plan_decorator)
    if user.email.present?
      mail({to: user.email, subject: "Your #{Settings.site.short_name} Enrollment Confirmation"}) do |format|
        format.html { render "plan_shopping_completed", :locals => { :user => user, :enrollment => hbx_enrollment, :plan => plan_decorator } }
      end
    end
  end

  def invitation_email(email, person_name, invitation)
    if email.present?
      mail({to: email, subject: "Invitation from your Employer to Sign up for Health Insurance at #{Settings.site.short_name} "}) do |format|
        format.html { render "invitation_email", :locals => { :person_name => person_name, :invitation => invitation }}
      end
    end
  end

  def renewal_invitation_email(email, census_employee, invitation)
    mail({to: email, subject: "Enroll Now: Your Health Plan Open Enrollment Period has Begun"}) do |format|
      format.html { render "renewal_invitation_email", :locals => { :census_employee => census_employee, :invitation => invitation }}
    end
  end

  def agent_invitation_email(email, person_name, invitation)
    if email.present?
      mail({to: email, subject: "DCHealthLink Support Invitation "}) do |format|
        format.html { render "agent_invitation_email", :locals => { :person_name => person_name, :invitation => invitation }}
      end
    end
  end

  def broker_invitation_email(email, person_name, invitation)
    if email.present?
      mail({to: email, subject: "Invitation to create your Broker account on #{Settings.site.short_name} "}) do |format|
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

  def new_client_notification(agent_email, first_name, name, role, insured_email, is_person)
    if agent_email.present?
      subject = "New Client Notification -[#{name}] email provided - [#{insured_email}]"
      mail({to: agent_email, subject: subject, from: 'no-reply@individual.dchealthlink.com'}) do |format|
        format.html { render "new_client_notification", :locals => { first_name: first_name, :role => role, name: name}}
      end
    end
  end

  def generic_consumer_welcome(first_name, hbx_id, email)
    if email.present?
      message = mail({to: email, subject: "DC HealthLink", from: 'no-reply@individual.dchealthlink.com'}) do |format|
        format.html {render "generic_consumer", locals: {first_name: first_name, hbx_id: hbx_id}}
      end
    end
  end

  def generic_notice_alert(first_name, notice_subject, email)
    message = mail({to: email, subject: "You have a new message from DC Health Link", from: 'no-reply@individual.dchealthlink.com'}) do |format|
      format.html {render "generic_notice_alert", locals: {first_name: first_name, notice_subject: notice_subject}}
    end
  end

  def employer_invoice_generation_notification(employer,subject)
    message = mail({to: employer.email, subject: subject, from: 'no-reply@individual.dchealthlink.com'}) do |format|
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
      mail({to: person.emails.find_by(kind: 'work').try(:address) , subject: "Thank you for submitting your broker application to #{Settings.site.short_name}"}) do |format|
        format.html { render "broker_application_confirmation", :locals => { :person => person }}
      end
    end
  end

  def broker_pending_notification(broker_role,unchecked_carriers)
    subject_sufix = unchecked_carriers.present? ? ", missing carrier appointments" : ", has all carrier appointments"
    subject_prefix = broker_role.training || broker_role.training == true ? "Completed NAHU Training" : "Needs to Complete NAHU training"
    subject="#{subject_prefix}#{subject_sufix}"
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
