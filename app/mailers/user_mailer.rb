class UserMailer < ApplicationMailer

  def welcome(user)
    mail({to: user.email, subject: "Thank you for registering."}) do |format|
      format.text
    end
  end

  def plan_shopping_completed(user, hbx_enrollment, plan_decorator)
    mail({to: user.email, subject: "Your #{Settings.site.short_name} Enrollment Confirmation"}) do |format|
      format.html { render "plan_shopping_completed", :locals => { :user => user, :enrollment => hbx_enrollment, :plan => plan_decorator } }
    end
  end

  def invitation_email(email, person_name, invitation)

    mail({to: email, subject: "Invitation from your Employer to Sign up for Health Insurance at #{Settings.site.short_name} "}) do |format|
      format.html { render "invitation_email", :locals => { :person_name => person_name, :invitation => invitation }}
    end
  end

  def agent_invitation_email(email, person_name, invitation)
    mail({to: email, subject: "DCHealthLink Support Invitation "}) do |format|
      format.html { render "agent_invitation_email", :locals => { :person_name => person_name, :invitation => invitation }}
    end
  end

  def broker_invitation_email(email, person_name, invitation)

    mail({to: email, subject: "Invitation to create your Broker account on #{Settings.site.short_name} "}) do |format|
      format.html { render "broker_invitation_email", :locals => { :person_name => person_name, :invitation => invitation }}
    end
  end

  def message_to_broker(person, broker, params)
    mail({to: broker.email_address, subject: params[:subject], from: person.user.email}) do |format|
      format.html { render "message_to_broker", :locals => { :person => person, :broker => broker, :message_body => params[:body] }}
    end
  end

  def new_client_notification(agent_email, first_name, name, role, insured_email, is_person)
    subject = "New Client Notification -[#{name}] email provided - [#{insured_email}]"
    mail({to: agent_email, subject: subject, from: 'no-reply@individual.dchealthlink.com'}) do |format|
      format.html { render "new_client_notification", :locals => { first_name: first_name, :role => role, name: name}}
    end
  end

  def generic_consumer_welcome(first_name, hbx_id, email)
    message = mail({to: email, subject: "DC HealthLink", from: 'no-reply@individual.dchealthlink.com'}) do |format|
      format.html {render "generic_consumer", locals: {first_name: first_name, hbx_id: hbx_id}}
    end
  end

  def broker_denied_notification(broker_role)
    mail({to: broker_role.email_address, subject: "Broker application denied"}) do |format|
      format.html { render "broker_denied", :locals => { :applicant_name => broker_role.person.full_name }}
    end
  end
end
