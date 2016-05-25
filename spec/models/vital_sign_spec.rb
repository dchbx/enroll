require 'rails_helper'

RSpec.describe VitalSign, :dbclean => :around_each do

  before (:all) do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end

  let(:shop_current_enrollment_count) { 1 }
  let(:shop_past_enrollment_count)    { 2 }
  let(:shop_total_enrollment_count)   { shop_current_enrollment_count + shop_past_enrollment_count }

  let(:shop_current_enrollments) do
    families = FactoryGirl.create_list(:family, shop_current_enrollment_count, :with_primary_family_member)
    shop_current_enrollment_count.times.map do |i|
      FactoryGirl.create(:hbx_enrollment,
                          household: families[i].active_household,
                          kind: "employer_sponsored",
                          submitted_at: TimeKeeper.datetime_of_record - 3.day,
                          created_at: TimeKeeper.datetime_of_record - 3.day
                        )
    end
  end

  let(:shop_past_enrollments) do
    families = FactoryGirl.create_list(:family, shop_past_enrollment_count, :with_primary_family_member)
    shop_past_enrollment_count.times.map do |i|
      FactoryGirl.create(:hbx_enrollment,
                          household: families[i].active_household,
                          kind: "employer_sponsored",
                          submitted_at: TimeKeeper.datetime_of_record - 5.days,
                          created_at: TimeKeeper.datetime_of_record - 5.days
                        )
    end
  end


  let(:ivl_current_enrollment_count) { 3 }
  let(:ivl_past_enrollment_count)    { 4 }
  let(:ivl_total_enrollment_count)   { ivl_current_enrollment_count + ivl_past_enrollment_count }

  let(:ivl_current_enrollments) do
    families = FactoryGirl.create_list(:family, ivl_current_enrollment_count, :with_primary_family_member)
    ivl_current_enrollment_count.times.map do |i|
      FactoryGirl.create(:hbx_enrollment,
                          household: families[i].active_household,
                          kind: "individual",
                          submitted_at: TimeKeeper.datetime_of_record - 3.day,
                          created_at: TimeKeeper.datetime_of_record - 3.day
                        )
    end
  end

  let(:ivl_past_enrollments) do
    families = FactoryGirl.create_list(:family, ivl_past_enrollment_count, :with_primary_family_member)
    ivl_past_enrollment_count.times.map do |i|
      FactoryGirl.create(:hbx_enrollment,
                          household: families[i].active_household,
                          kind: "individual",
                          submitted_at: TimeKeeper.datetime_of_record - 5.days,
                          created_at: TimeKeeper.datetime_of_record - 5.days
                        )
    end
  end

  context "New VitalSign query is created without date/time constraints" do
    let(:vital_sign)  { VitalSign.new }

    before :each do
      shop_past_enrollments
      shop_current_enrollments
      ivl_past_enrollments
      ivl_current_enrollments
    end

    it "should find all enrollments" do
      expect(vital_sign.all_enrollments.size).to eq (shop_total_enrollment_count + ivl_total_enrollment_count)
    end

    it "should find all individual enrollments" do
      expect(vital_sign.all_individual_enrollments.size).to eq ivl_total_enrollment_count
    end

    it "should find all SHOP enrollments" do
      expect(vital_sign.all_shop_enrollments.size).to eq shop_total_enrollment_count
    end

  end

  # context "New VitalSign query is created with date/time constrained to last 24 hours" do
  #   let(:start_at)    { TimeKeeper.datetime_of_record }
  #   let(:end_at)      { TimeKeeper.datetime_of_record }
  #   let(:vital_sign)  { VitalSign.new(start_at, end_at) }

  # end
end
