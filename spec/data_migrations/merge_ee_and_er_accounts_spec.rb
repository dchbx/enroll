require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "merge_ee_and_er_accounts")

describe MergeEeAndErAccounts, dbclean: :after_each do

  let(:given_task_name) { "merge ee and er accounts" }
  subject { MergeEeAndErAccounts.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "merge ee and er roles" do

    let!(:user) { FactoryGirl.create(:user, person: employer_staff_role.person)}
    let(:person)  {FactoryGirl.create(:person,:with_employee_role, hbx_id: "1234567")}
    let(:employer_staff_role) {FactoryGirl.create(:employer_staff_role,employer_profile_id:employer_profile.id)}
    let(:employer_profile){FactoryGirl.create(:employer_profile)}

    before(:each) do
      allow(ENV).to receive(:[]).with("employee_hbx_id").and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with("employer_hbx_id").and_return(employer_staff_role.person.hbx_id)
    end

    context "giving a new state" do
      it "should assign user to the employee" do
        expect(person.employer_staff_roles).to eq []
        expect(person.user).to eq nil
        expect(employer_staff_role.person.user).not_to eq nil
        subject.migrate
        person.reload
        expect(person.employer_staff_roles).not_to eq nil
        expect(person.user).not_to eq nil
        expect(person.user.roles).to include("employee")
      end
    end
  end
end
