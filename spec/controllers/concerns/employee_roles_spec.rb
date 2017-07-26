require 'rails_helper'

class FakesController < ApplicationController
  include EmployeeRoles
end

describe FakesController do
  let(:person) { FactoryGirl.create(:person)}
  let(:employee_role1) { FactoryGirl.create(:employee_role)}
  let(:employee_role2) { FactoryGirl.create(:employee_role)}

  before do
    employee_role1.update_attributes(contact_method: "Paper and Electronic communications")
    employee_role1.update_attributes(language_preference: "Spanish")
    allow(person).to receive(:active_employee_roles).and_return [employee_role1, employee_role2]
    subject.set_notice_preference(person, employee_role1)
  end

  it "should set the contact_method on the other active employee roles from the current ER" do
    employee_role2.reload
    expect(employee_role2.contact_method).to eq employee_role1.contact_method
  end

  it "should set the language_preference on the other active employee roles from the current ER" do
    employee_role2.reload
    expect(employee_role2.language_preference).to eq employee_role1.language_preference
  end
end
