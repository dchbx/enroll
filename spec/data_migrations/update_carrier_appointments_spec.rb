require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_carrier_appointments")

describe UpdateCarrierAppointments do

  let(:given_task_name) { "update_carrier_appointments" }
  subject { UpdateCarrierAppointments.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "migrating old pending broker records" do
    before do
    @broker_role = FactoryGirl.create(:broker_role, carrier_appointments: { "aetna_health_inc"=>nil, 
      "aetna_life_insurance_company" =>nil, 
       "optimum_choice"=>nil, 
      "united_health_care_insurance"=>nil, "united_health_care_mid_atlantic"=>nil, 
      "carefirst_bluechoice_inc"=>"true", 
      "group_hospitalization_and_medical_services_inc"=>"true", "kaiser_foundation"=>"true"}) 
      @value = {"Aetna Health Inc" => nil, "Aetna Life Insurance Company"=>nil, "Carefirst Bluechoice Inc"=>"true", "Group Hospitalization and Medical Services Inc"=>"true", "Kaiser Foundation"=>"true", "Optimum Choice"=>nil, "United Health Care Insurance"=>nil, "United Health Care Mid Atlantic"=>nil}
    end

    it "should return new carrier appointments for pending brokers " do
      allow(BrokerRole).to receive(:all).and_return([@broker_role])
      subject.migrate
      expect(@broker_role.carrier_appointments).to eq  @value
    end

    it "should return value for the combination of old & new carrier appointments " do
      @broker_role.carrier_appointments.store("Aetna Life Insurance Company", nil)
      allow(BrokerRole).to receive(:all).and_return([@broker_role])
      subject.migrate
      expect(@broker_role.carrier_appointments).to eq  @value
    end

    it "should return value for value " do
     @broker_role = FactoryGirl.create(:broker_role, carrier_appointments: @value)
      allow(BrokerRole).to receive(:all).and_return([@broker_role])
      subject.migrate
      expect(@broker_role.carrier_appointments).to eq  @value
    end

  end

end

