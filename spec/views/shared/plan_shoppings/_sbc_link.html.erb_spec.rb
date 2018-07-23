require 'rails_helper'

RSpec.describe "shared/plan_shoppings/_sbc_link.html.erb" do

  let(:aws_env) { ENV['AWS_ENV'] || "qa" }
  let(:mock_carrier_profile) { instance_double("CarrierProfile", :dba => "a carrier name", :legal_name => "name") }
  let(:mock_plan) { double("Plan",
      :name => "A Plan Name",
      :carrier_profile_id => "a carrier profile id",
      :carrier_profile => mock_carrier_profile,
      :metal_level => "Silver",
      :plan_type => "A plan type",
      :nationwide => true,
      :deductible => 0,
      :total_premium => 0,
      :total_employer_contribution => 0,
      :total_employee_cost => 0,
      :ehb => 0.988,
      :coverage_kind => 'health',
      :id => "1234234234",
      :sbc_file => "THE SBC FILE.PDF",
      :sbc_document => Document.new({title: 'sbc_file_name', subject: "SBC",
                                     :identifier=>"urn:openhbx:terms:v1:file_storage:s3:bucket:#{Settings.site.s3_prefix}-enroll-sbc-#{aws_env}#7816ce0f-a138-42d5-89c5-25c5a3408b82"})
      ) }

  before :each do
    render partial: "shared/plan_shoppings/sbc_link", locals: {plan: mock_plan}
  end

  it "should have the sbc link" do
    expect(rendered).to have_selector("a[href='#{"/document/download/#{Settings.site.s3_prefix}-enroll-sbc-#{aws_env}/7816ce0f-a138-42d5-89c5-25c5a3408b82?content_type=application/pdf&filename=APlanName.pdf&disposition=inline"}']")
  end

  context "with dental coverage_kind" do
    before :each do
      allow(mock_plan).to receive(:coverage_kind).and_return('dental')
      render partial: "shared/plan_shoppings/sbc_link", locals: {plan: mock_plan}
    end

    it "should have the sbc link with dental text" do
      expect(rendered).to have_selector('a', text:'Plan Summary')
    end

  end

end
