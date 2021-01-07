require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'activate_benefit_group_assignment')

describe ActivateBenefitGroupAssignment do

  let(:given_task_name) { 'activate_benefit_group_assignment' }
  subject { ActivateBenefitGroupAssignment.new(given_task_name, double(:current_scope => nil)) }
  let(:bga_params) {{ce_id: census_employee.id, dep_id: census_dependent.id, dep_ssn: census_dependent.ssn}}

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'activate benefit group assignment' do
    let!(:census_employee) { FactoryBot.create(:census_employee,ssn:'123456789')}
    let!(:benefit_group_assignment1)  { FactoryBot.create(:benefit_group_assignment, census_employee: census_employee)}
    let!(:benefit_group_assignment2)  { FactoryBot.create(:benefit_group_assignment, census_employee: census_employee)}
    let!(:bga_params) {{ce_ssn: census_employee.ssn, bga_id: benefit_group_assignment1.id}}

    around do |example|
      ClimateControl.modify bga_params do
        example.run
      end
    end

    context 'activate_benefit_group_assignment', dbclean: :after_each do
      it 'should activate_related_benefit_group_assignment' do
        expect(benefit_group_assignment1.activated_at).to be_falsey
        subject.migrate
        census_employee.reload
        expect(census_employee.benefit_group_assignments.where(id: benefit_group_assignment1.id).first.activated_at.class).to eq DateTime
      end
      it 'should_not activate_unrelated_benefit_group_assignment' do
        expect(benefit_group_assignment2.activated_at).to be_falsey
        subject.migrate
        census_employee.reload
        expect(census_employee.benefit_group_assignments.where(id: benefit_group_assignment2.id).first.activated_at.class).to eq NilClass
      end
    end
  end
end
