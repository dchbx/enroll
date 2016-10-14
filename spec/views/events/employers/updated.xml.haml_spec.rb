require 'rails_helper'
require File.join(Rails.root, "spec", "support", "acapi_vocabulary_spec_helpers")

RSpec.describe "events/employers/updated.haml.erb" do
  let(:legal_name) { "A Legal Employer Name" }
  let(:fein) { "867530900" }
  let(:entity_kind) { "c_corporation" }

  let(:organization) { Organization.new(:legal_name => legal_name, :fein => fein, :is_active => false) }

  describe "given a single plan year" do
    include AcapiVocabularySpecHelpers

    before(:all) do
      download_vocabularies
    end

    let(:plan_year) { PlanYear.new(:aasm_state => "published", :created_at => DateTime.now, 
                                  :start_on => DateTime.now,
                                  :open_enrollment_start_on => DateTime.now, 
                                  :open_enrollment_end_on => DateTime.now) 
                    }
    let(:employer) { EmployerProfile.new(:organization => organization, :plan_years => [plan_year], :entity_kind => entity_kind) }

    before :each do
      render :template => "events/employers/updated", :locals => { :employer => employer }
    end

    it "should have one plan year" do
      expect(rendered).to have_xpath("//plan_years/plan_year")
    end


    it "should be schema valid" do
      expect(validate_with_schema(Nokogiri::XML(rendered))).to eq []
    end

    context "with dental plans" do

      let(:benefit_group) {bg = FactoryGirl.create(:benefit_group, plan_year: plan_year);
                          bg.elected_dental_plans = [FactoryGirl.create(:plan, name: "new dental plan", coverage_kind: 'dental',
                                                 dental_level: 'high')];
                          bg}

      context "is_offering_dental? is true" do
        it "shows the dental plan in output" do
          benefit_group.dental_reference_plan_id = benefit_group.elected_dental_plans.first.id
          plan_year.benefit_groups.first.save!
          render :template => "events/employers/updated", :locals => {:employer => employer}
          expect(rendered).to include "new dental plan"
        end
      end


      context "is_offering_dental? is false" do
        it "does not show the dental plan in output" do
          benefit_group.dental_reference_plan_id = nil
          benefit_group.save!
          render :template => "events/employers/updated", :locals => {:employer => employer}
          expect(rendered).not_to include "new dental plan"
        end
      end
    end

    context "point of contacts" do

      context "has staff roles" do
        let(:staff1) { FactoryGirl.create(:person, first_name: 'name1') }
        let(:staff2) { FactoryGirl.create(:person, first_name: 'name2') }

        before(:each) do
          allow(employer).to receive(:staff_roles).and_return([staff1, staff2])
          render :template => "events/employers/updated", :locals => {:employer => employer}
        end

        it "adds the staff roles to the contacts section in xml" do
          expect(rendered).to have_selector('contact', count: 2)
          expect(rendered).to have_xpath("//contacts/contact/person_name/person_given_name", :text => "name1")
          expect(rendered).to have_xpath("//contacts/contact/person_name/person_given_name", :text => "name2")
        end

        context "duplicate staff" do
          before(:each) do
            allow(employer).to receive(:staff_roles).and_return([staff1, staff2, staff1, staff1])
          end

          it "does not add duplicate staff roles to the contacts section in xml" do
            expect(rendered).to have_selector('contact', count: 2)
            expect(rendered).to have_xpath("//contacts/contact/person_name/person_given_name", :text => "name1")
            expect(rendered).to have_xpath("//contacts/contact/person_name/person_given_name", :text => "name2")
          end
        end
      end

      context "does not have staff roles but has owners" do
        let(:owner1) { FactoryGirl.create(:person, first_name: 'name3') }
        let(:owner2) { FactoryGirl.create(:person, first_name: 'name4') }

        before(:each) do
          allow(employer).to receive(:staff_roles).and_return([])
          allow(employer).to receive(:owners).and_return([owner1, owner2])
          render :template => "events/employers/updated", :locals => {:employer => employer}
        end

        it "adds the owners to the contacts section in xml" do
          expect(rendered).to have_selector('contact', count: 2)
          expect(rendered).to have_xpath("//contacts/contact/person_name/person_given_name", :text => "name3")
          expect(rendered).to have_xpath("//contacts/contact/person_name/person_given_name", :text => "name4")
        end
      end

      context "staff is owner" do
        let(:staff_and_owner) { FactoryGirl.create(:person, first_name: 'name5') }

        before do
          allow(employer).to receive(:staff_roles).and_return([staff_and_owner])
          allow(employer).to receive(:owners).and_return([staff_and_owner])
          render :template => "events/employers/updated", :locals => {:employer => employer}
        end

        it "includes only one contact in xml" do
          expect(rendered).to have_selector('contact', count: 1)
          expect(rendered).to have_xpath("//contacts/contact/person_name/person_given_name", :text => "name5")
        end
      end
    end

  end

  (1..15).to_a.each do |rnd|

    describe "given a generated employer, round #{rnd}" do
      include AcapiVocabularySpecHelpers

      before(:all) do
        download_vocabularies
      end

      let(:employer) { FactoryGirl.build_stubbed :generative_employer_profile }
      let(:staff) { FactoryGirl.create(:person, :with_work_email, :with_work_phone)}

      before :each do
        allow(employer).to receive(:staff_roles).and_return([staff])
        render :template => "events/employers/updated", :locals => { :employer => employer }
      end

      it "should be schema valid" do
        expect(validate_with_schema(Nokogiri::XML(rendered))).to eq []
      end

    end

  end
end
