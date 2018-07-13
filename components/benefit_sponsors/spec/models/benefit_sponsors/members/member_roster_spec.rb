require 'rails_helper'

module BenefitSponsors
  RSpec.describe Members::MemberRoster, type: :model do

    let(:employee_1)    { FactoryGirl.build(:benefit_sponsors_members_employee_member, :as_male) }

    let(:employee_2)    { FactoryGirl.build(:benefit_sponsors_members_employee_member, :as_male) }
    let(:spouse_2)      { FactoryGirl.build(:benefit_sponsors_members_dependent_member, :as_spouse) }

    let(:employee_3)    { FactoryGirl.build(:benefit_sponsors_members_employee_member,  :as_female) }
    let(:spouse_3)      { FactoryGirl.build(:benefit_sponsors_members_dependent_member, :as_female_domestic_partner) }
    let(:child_3)       { FactoryGirl.build(:benefit_sponsors_members_dependent_member, :as_child) }

    let(:member_group_1)  { Members::MemberGroup.new([employee_1]) }
    let(:member_group_2)  { Members::MemberGroup.new([employee_2, spouse_2]) }
    let(:member_group_3)  { Members::MemberGroup.new([employee_3, spouse_3, child_3]) }


    context "A new MemberRoster instance" do
      let(:member_roster)  { described_class.new }

      it "should have an empty member_groups list" do
        expect(member_roster.member_groups).to eq []
      end

      context "and a new member_group is added" do

        before { member_roster.add_member_group(member_group_1) }

        it "should add the member_group to the MemberRoster" do
          expect(member_roster.member_groups.size).to eq 1
          expect(member_roster.member_groups.first).to eq member_group_1
        end

        context "and additional member_groups are added" do 
          before { 
                    member_roster.add_member_group(member_group_2)
                    member_roster.add_member_group(member_group_3)
                  }

          it "should included the added member_groups" do
            expect(member_roster.member_groups.size).to eq 3
            expect(member_roster.member_groups).to include(member_group_3)
          end

          context "and a member_group is dropped" do 
            it "should remove the member from the group" do
              expect(member_roster.member_groups).to include(member_group_3)
              member_roster.drop_member_group(member_group_3)
              expect(member_roster.member_groups).not_to include(member_group_3)
            end
          end

        end
      end

    end 

  end
end
