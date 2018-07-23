require 'rails_helper'

module BenefitSponsors
  module Observers
    RSpec.describe EmployerStaffRoleObserver, type: :model, dbclean: :after_each do
      subject { EmployerStaffRoleObserver.new }

      let(:staff_role) { create :benefit_sponsor_employer_staff_role }

      before do
        allow(subject).to receive(:notify).exactly(1).times
      end

      context 'when staff role not changed' do
        before do
          subject.contact_changed?(staff_role)
        end

        it 'should not notify' do
          expect(subject).not_to have_received(:notify).with("acapi.info.events.employer.contact_changed", {employer_id: staff_role.hbx_id , event_name: "contact_changed"})
        end
      end

      # You cannot modify person info on staff role. All you can do is closing ER staff role
      context 'when staff role changed' do
        before do
          staff_role.assign_attributes({
            is_active: false
          })

          subject.contact_changed?(staff_role)
        end

        it 'should notify' do
          expect(subject).to have_received(:notify).with("acapi.info.events.employer.contact_changed", {employer_id: staff_role.hbx_id , event_name: "contact_changed"})
        end
      end
    end
  end
end
