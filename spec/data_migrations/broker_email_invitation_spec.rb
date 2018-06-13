require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "broker_email_invitation")

describe BrokerEmailInvitation, dbclean: :after_each do
  let(:given_task_name) { "broker_email_invitation" }
  subject { BrokerEmailInvitation.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "Send invitation to the broker" do
    let(:registered_broker_role) {FactoryGirl.create(:broker_role, npn: "2323334", aasm_state:"active")}
    before do
      allow(ENV).to receive(:[]).with("npn").and_return(registered_broker_role.npn)
    end
    it "count of the invitation email for the broker role should increase" do
     expect(Invitation.where(:source_id => registered_broker_role.id).count ).to eq 0
     subject.migrate
     expect(Invitation.where(:source_id => registered_broker_role.id).count ).to eq 1
    end
  end

  describe "Already invited broker should not be sent an invitation" do    
    let(:registered_broker_role) {FactoryGirl.create(:broker_role, npn: "2323334", aasm_state:"active")}
    let(:invitation) { FactoryGirl.create(:invitation, :broker_role, :source_id => registered_broker_role.id, :invitation_email => registered_broker_role.email_address)}
    before do
      allow(ENV).to receive(:[]).with("npn").and_return(registered_broker_role.npn)
    end
    it "count of the invitation email for the broker role should not increase" do
     invitation.reload
     expect(Invitation.where(:source_id => registered_broker_role.id).count ).to eq 1
     subject.migrate
     expect(Invitation.where(:source_id => registered_broker_role.id).count ).to eq 1
    end
  end

  describe "Do not send an invitation to the broker who is not in active state" do
    let(:registered_broker_role) {FactoryGirl.create(:broker_role, npn: "2323334", aasm_state:"broker_agency_pending")}
    before do
      allow(ENV).to receive(:[]).with("npn").and_return(registered_broker_role.npn)
    end
    it "count of the invitation email for the broker role should not increase" do
     expect(Invitation.where(:source_id => registered_broker_role.id).count ).to eq 0
     subject.migrate
     expect(Invitation.where(:source_id => registered_broker_role.id).count ).to eq 0
    end
  end
end