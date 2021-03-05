# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, "spec", "support", "acapi_vocabulary_spec_helpers")
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe 'events/v2/employers/_plan_year.haml', dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  describe "given a employer", dbclean: :around_each do
    include AcapiVocabularySpecHelpers

    before(:all) do
      download_vocabularies
    end

    before :each do
      render partial: 'events/v2/employers/plan_year', :collection => [initial_application], as: :plan_year
      @doc = Nokogiri::XML(rendered)
      @plan_years = @doc.xpath("//plan_year")
    end

    it "should have one plan year" do
      expect(@plan_years.count).to eq(1)
    end

    it 'should match start_date' do
      date = @plan_years.first.children.detect{|ch| ch.name == "plan_year_start"}.text
      expect(Date.strptime(date, '%Y%m%d')).to eq initial_application.effective_period.min
    end

    context "when plan year is reinstated" do
      let(:start_date) {TimeKeeper.date_of_record.beginning_of_month - 11.months}
      let(:end_date) {(start_date + 6.months).end_of_month}
      let(:effective_period) {start_date..end_date}
      let(:start_date1) {end_date.next_day}
      let(:end_date1) {TimeKeeper.date_of_record.end_of_month}
      let(:effective_period1) {start_date1..end_date1}
      let(:open_enrollment_start_on) { start_date - 1.month }
      let(:open_enrollment_start_on1) { end_date.beginning_of_month }
      let(:open_enrollment_period) {open_enrollment_start_on..(open_enrollment_start_on + 5.days)}
      let(:open_enrollment_period) {open_enrollment_start_on1..(open_enrollment_start_on1 + 5.days)}
      let(:reinstated_application1) do
        create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog,
               :with_benefit_package,
               passed_benefit_sponsor_catalog: benefit_sponsor_catalog,
               benefit_sponsorship: benefit_sponsorship,
               effective_period: effective_period1,
               aasm_state: aasm_state,
               open_enrollment_period: open_enrollment_period,
               recorded_rating_area: rating_area,
               recorded_service_areas: service_areas,
               package_kind: package_kind,
               dental_package_kind: dental_package_kind,
               dental_sponsored_benefit: dental_sponsored_benefit,
               fte_count: 5,
               pte_count: 0,
               msp_count: 0,
               reinstated_id: initial_application.id)
      end

      before do
        initial_application.update_attributes!(:aasm_state => :terminated, effective_period: effective_period)
        abc_profile.benefit_applications << [reinstated_application1]
        abc_profile.save!
        render partial: 'events/v2/employers/plan_year', :collection => [reinstated_application1], as: :plan_year
        @doc = Nokogiri::XML(rendered)
        @plan_years = @doc.xpath("//plan_year")
      end

      it "should have one plan year" do
        expect(@plan_years.count).to eq 1
      end

      it "should return initial_application's effective_period start_date" do
        date = @plan_years.first.children.detect{|ch| ch.name == "plan_year_start"}.text
        expect(Date.strptime(date, '%Y%m%d')).to eq initial_application.effective_period.min
      end

      it "should not return reinstated_application's effective_period start_date" do
        date = @plan_years.first.children.detect{|ch| ch.name == "plan_year_start"}.text
        expect(Date.strptime(date, '%Y%m%d')).not_to eq reinstated_application1.effective_period.min
      end
    end
  end
end
