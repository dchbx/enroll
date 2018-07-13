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
    @broker_role = FactoryGirl.create(:broker_role, carrier_appointments: { "altus" => nil,
                                                                            "blue_cross_blue_shield_ma" => nil,
                                                                            "boston_medical_center_health_plan" => nil,
                                                                            "delta" => nil,
                                                                            "FCHP" => nil,
                                                                            "guardian" => nil,
                                                                            "health_new_england" => nil,
                                                                            "harvard_pilgrim_health_care" => nil,
                                                                            "minuteman_health" => nil,
                                                                            "neighborhood_health_plan" => nil,
                                                                            "tufts_health_plan_direct" => nil,
                                                                            "tufts_health_plan_premier" => nil}) 
      @value = {"Altus" => nil,
                "Blue Cross Blue Shield MA" => nil,
                "Boston Medical Center Health Plan" => nil,
                "Delta" => nil,
                "FCHP" => nil,
                "Guardian" => nil,
                "Health New England" => nil,
                "Harvard Pilgrim Health Care" => nil,
                "Minuteman Health" => nil,
                "Neighborhood Health Plan" => nil,
                "Tufts Health Plan Direct" => nil,
                "Tufts Health Plan Premier" => nil}
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

