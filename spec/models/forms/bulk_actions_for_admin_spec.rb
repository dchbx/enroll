require "rails_helper"

describe Forms::BulkActionsForAdmin do

  let(:params) { {
    :family_actions_id => "family_actions_5824903a7af880f17a000009",
    :family_id => "5824903a7af880f17a000009",
    :commit => "Submit",
    :controller => "exchanges/hbx_profiles",
    :action => "update_cancel_enrollment"}
  }

  subject {
    Forms::BulkActionsForAdmin.new(params)
  }

  context 'initialize new form model with the params from the controller' do

    it "should store the value of params[:family_id] in the @family_id variable" do
      expect(subject.family_id).to eq(params[:family_id])
    end

    it "should store the value of params[:family_actions_id] in the @row variable" do
      expect(subject.row).to eq(params[:family_actions_id])
    end

    it "should store the value of params[:result] in the @row variable" do
      expect(subject.row).to eq(params[:family_actions_id])
    end
  end

  context 'enrollment market' do
    context "SHOP" do
      let(:termination_date) { Date.today + 1.month }
      let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
      let(:hbx_enrollment) do
        FactoryBot.create(:hbx_enrollment, :shop, family: family, aasm_state: 'coverage_enrolled')
      end
      let(:terminate_params) do
        {
          :family_actions_id => "family_actions_#{family.id}",
          :family_id => family.id,
          :commit => "Submit",
          :controller => "exchanges/hbx_profiles",
          "terminate_hbx_#{hbx_enrollment.id}" => hbx_enrollment.id.to_s,
          "termination_date_#{hbx_enrollment.id}" => termination_date.to_s
        }
      end
      let(:bulk_actions_for_admin) do
        Forms::BulkActionsForAdmin.new(terminate_params)
      end

      before :each do
        hbx_enrollment
        allow(bulk_actions_for_admin).to receive(:handle_edi_transmissions).with(hbx_enrollment.id, false).and_return(true)
        bulk_actions_for_admin.terminate_enrollments
        hbx_enrollment.reload
      end

      it 'sends enrollment to coverage_termination_pending' do
        expect(hbx_enrollment.aasm_state).to eq('coverage_termination_pending')
      end
    end

    context "IVL" do
      let(:termination_date) { Date.today + 1.month }
      let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
      let(:hbx_enrollment) do
        FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, aasm_state: 'coverage_enrolled')
      end
      let(:terminate_params) do
        {
          :family_actions_id => "family_actions_#{family.id}",
          :family_id => family.id,
          :commit => "Submit",
          :controller => "exchanges/hbx_profiles",
          "terminate_hbx_#{hbx_enrollment.id}" => hbx_enrollment.id.to_s,
          "termination_date_#{hbx_enrollment.id}" => termination_date.to_s
        }
      end
      let(:bulk_actions_for_admin) do
        Forms::BulkActionsForAdmin.new(terminate_params)
      end

      before :each do
        hbx_enrollment
        allow(bulk_actions_for_admin).to receive(:handle_edi_transmissions).with(hbx_enrollment.id, false).and_return(true)
        bulk_actions_for_admin.terminate_enrollments
        hbx_enrollment.reload
      end

      it 'sends enrollment directly to coverage_terminated' do
        expect(hbx_enrollment.aasm_state).to eq('coverage_terminated')
      end
    end
  end
end
