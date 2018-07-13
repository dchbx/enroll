require 'rails_helper'

module BenefitSponsors
  RSpec.describe Members::Member, type: :model do

    let(:employee_member) { described_class.new }

    let(:first_name)      { "first_name" }
    let(:middle_name)     { "middle_name" }
    let(:last_name)       { "last_name" }
    let(:name_sfx)        { "name_sfx" }

    let(:gender)          { :male }
    let(:dob)             { Date.new(1966,5,25) }

    let(:kinship_to_primary_member)  { :spouse }
    let(:sponsor_assigned_id)       { "3432" }

    let(:params) do
      {
        first_name: first_name,
        middle_name: middle_name,
        last_name: last_name,
        name_sfx: name_sfx,
        gender: gender,
        dob: dob,
        kinship_to_primary_member: kinship_to_primary_member,
        sponsor_assigned_id: sponsor_assigned_id,

        # TODO: add following parameters to spec
        # address: address,
        # email: email,
      }
    end

    context "A new model instance" do

      context "with no arguments" do
        subject { described_class.new }

        it "should be valid" do
          subject.validate
          expect(subject).to be_valid
        end
      end

      context "with all valid arguments" do
        subject { described_class.new(params) }

        it "should be valid" do
          subject.validate
          expect(subject).to be_valid
        end

        it "attributes should be set to passed argument values" do
          expect(subject.first_name).to eq first_name
          expect(subject.middle_name).to eq middle_name
          expect(subject.last_name).to eq last_name
          expect(subject.name_sfx).to eq name_sfx
          expect(subject.gender).to eq gender
          expect(subject.dob).to eq dob
          expect(subject.kinship_to_primary_member).to eq kinship_to_primary_member
          expect(subject.sponsor_assigned_id).to eq sponsor_assigned_id

          # expect(subject.address).to eq address
          # expect(subject.email).to eq email
        end
      end
    end

    context "with arguments for gender" do
      context "with invalid gender value" do
        let(:invalid_gender)     { :mail }

        it "should be invalid" do
          employee_member.gender = invalid_gender
          employee_member.validate
          expect(employee_member).to be_invalid
        end
      end

      context "with capitalized string" do
        let(:all_caps_gender_string)  { "MALE" }

        it "transforms to valid gender" do
          employee_member.gender = all_caps_gender_string
          expect(employee_member.gender).to eq :male
        end
      end

      context "with missing gender value" do
        let(:nil_gender)              { nil }

        it "should be nil" do
          employee_member.gender = nil_gender
          expect(employee_member.gender).to be_nil
        end

        it "should be valid" do
          employee_member.gender = nil_gender
          employee_member.validate
          expect(employee_member).to be_valid
        end
      end
    end

    context "with arguments for date of birth" do
      let(:dob_as_date)     { Date.new(dob_year,dob_month,dob_day) }
      let(:dob_year)        { 1980 }
      let(:dob_month)       { 3 }
      let(:dob_day)         { 31 }

      let(:member)          { described_class.new }

      context "set date of birth from a string value" do
        let(:dob_as_string)   { "#{dob_year}-#{dob_month}-#{dob_day}" }

        it "sets date of birth from string value" do
          member.dob = dob_as_string
          expect(member.dob).to eq dob_as_date
        end
      end

      context "dob more than 110 years ago" do
        let(:old_dob) { 111.years.ago } 

        it "should be invalid" do
          member.dob = old_dob
          member.validate
          expect(member).to be_invalid

          expect(member.errors[:dob].first[:message]).to match(/date of birth cannot be more than 110 years ago/)
        end
      end

      context "date of birth is in the future" do
        let(:future_dob)  { TimeKeeper.date_of_record + 1.day }

        it "should be invalid" do
          member.dob = future_dob
          member.validate
          expect(member).to be_invalid

          expect(member.errors[:dob].first[:message].to_s).to match(/future date: #{future_dob.to_s} is not valid for date of birth/)
        end
      end

      context "with a valid date of birth" do
        let(:today)         { TimeKeeper.date_of_record }
        let(:age_today)     { 36 }
        let(:age_tomorrow)  { age_today + 1 }
        let(:date_of_birth) { today - 37.years + 1.day }

        it "should correctly calculate the member's age" do
          member.dob = date_of_birth
          expect(member.age_on(today)).to eq age_today
          expect(member.age_on(today + 1)).to eq age_tomorrow
        end

      end



    end



  end
end
