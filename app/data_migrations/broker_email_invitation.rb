require File.join(Rails.root, "lib/mongoid_migration_task")
class BrokerEmailInvitation < MongoidMigrationTask
  def migrate
    npn = ENV['npn'].to_s
    broker_role = BrokerRole.find_by_npn(npn)
    if broker_role.nil?
        puts "No Broker was found with given npn" unless Rails.env.test?
        return
    end    
    broker_email = broker_role.email_address
    invitation = Invitation.where(invitation_email: broker_email)
    aasm_state = broker_role.aasm_state

    if broker_email.present?
        if (invitation.empty? && aasm_state == "active")
          Invitation.invite_broker!(broker_role)
        else
         puts "Broker has already been sent a signup invitation email" unless Rails.env.test?
        end 
    end
  end
end
