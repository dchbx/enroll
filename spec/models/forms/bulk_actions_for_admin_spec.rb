require "rails_helper"

describe Forms::BulkActionsForAdmin, ".cancel_enrollments" do

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
end
