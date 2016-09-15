require 'rails_helper'

RSpec.describe "insured/families/_navigation.html.erb" do

  let(:user){ instance_double("User") }
  let(:person){
    instance_double(
      "Person",
      first_name: "my first name",
      last_name: "my last name"
      )
  }
  let(:employee_role){ instance_double("EmployeeRole") }
  let(:employer_profile){ instance_double("EmployerProfile") }
  let(:broker_agency_profile){ instance_double("BrokerAgencyProfile") }
  let(:inbox){ instance_double("Inbox") }
  let(:active_family_members){ instance_double("ActiveFamilyMembers")}
  def family_member
    random_value = rand(999_999_999)
    instance_double(
      "FamilyMember#{random_value}",
      first_name: "my real first name #{random_value}",
      last_name: "my real last name #{random_value}"
      )
  end

  let(:family_members){ [ family_member, family_member ] }

  before :each do
    allow(user).to receive(:person).and_return(person)
    allow(person).to receive(:has_active_employee_role?).and_return(true)
    allow(person).to receive(:has_consumer_role?).and_return(true)
    allow(person).to receive(:inbox).and_return(inbox)
    allow(view).to receive(:enrollment_group_unverified?)
    allow(view).to receive(:verification_needed?)
    allow(view).to receive(:documents_uploaded)
    allow(inbox).to receive(:unread_messages).and_return(3)
    allow(employee_role).to receive(:employer_profile).and_return(employer_profile)
    allow(employer_profile).to receive(:broker_agency_profile).and_return(broker_agency_profile)
    assign(:person, person)
    assign(:family_members, family_members)
    assign(:employee_role, employee_role)
  end

  context "family has unverified members" do
    describe "has unverified enrollments" do
      before :each do
        allow(user).to receive(:person).and_return(person)
        allow(view).to receive(:enrollment_group_unverified?).and_return true
        allow(view).to receive(:verification_needed?).and_return true
        render partial: "insured/families/navigation.html.erb"
      end

      it "should match the side bar tabs info on family home page" do
        expect(rendered).to have_selector('a[href="/families/home?tab=home"]', text: "My #{Settings.site.short_name}")
        expect(rendered).to have_selector('a[href="/insured/families/brokers?tab=broker"]', text: 'My Broker')
        expect(rendered).to have_selector('a[href="/insured/families/verification?tab=verification"]', text: 'Documents')
        expect(rendered).to have_selector('a[href="/insured/families/inbox?tab=messages"]', text: 'Messages')
      end

      it "should display the info under my account in the side bar" do
        expect(rendered).to have_selector('h4', 'My Account')
        expect(rendered).to have_selector('span', "#{person.first_name} #{person.last_name}")
        expect(rendered).to have_selector('span', "Your household of #{family_members.count}")
      end

      it "should display the list of active household" do
        family_members.each do |family_member|
          expect(rendered).to match(/#{family_member.first_name} #{family_member.last_name}/)
        end
      end

      it "should have a link to manage family button" do
        expect(rendered).to have_selector('a[href="/insured/families/manage_family?tab=family"]', text: 'Manage Family')
      end

      it "shows action needed label" do
        expect(rendered).to match(/Action Needed/)
      end
    end
    describe "no unverified enrollments" do
      before :each do
        allow(view).to receive(:enrollment_group_unverified?).and_return true
        allow(view).to receive(:verification_needed?).and_return false
        render partial: "insured/families/navigation.html.erb"
      end

      it "should match the side bar tabs info on family home page" do
        expect(rendered).to have_selector('a[href="/families/home?tab=home"]', text: "My #{Settings.site.short_name}")
        expect(rendered).to have_selector('a[href="/insured/families/brokers?tab=broker"]', text: 'My Broker')
        expect(rendered).to have_selector('a[href="/insured/families/verification?tab=verification"]', text: 'Documents')
        expect(rendered).to have_selector('a[href="/insured/families/inbox?tab=messages"]', text: 'Messages')
      end

      it "should display the info under my account in the side bar" do
        expect(rendered).to have_selector('h4', 'My Account')
        expect(rendered).to have_selector('span', "#{person.first_name} #{person.last_name}")
        expect(rendered).to have_selector('span', "Your household of #{family_members.count}")
      end

      it "should display the list of active household" do
        family_members.each do |family_member|
          expect(rendered).to match(/#{family_member.first_name} #{family_member.last_name}/)
        end
      end

      it "should have a link to manage family button" do
        expect(rendered).to have_selector('a[href="/insured/families/manage_family?tab=family"]', text: 'Manage Family')
      end

      it "doesn't show action needed label" do
        expect(rendered).to_not match(/Action Needed/)
      end
    end

    describe "with uploaded documents" do
      before :each do
        allow(view).to receive(:enrollment_group_unverified?).and_return true
        allow(view).to receive(:verification_needed?).and_return true
        allow(view).to receive(:documents_uploaded).and_return true
        render partial: "insured/families/navigation.html.erb"
      end

      it "should match the side bar tabs info on family home page" do
        expect(rendered).to have_selector('a[href="/families/home?tab=home"]', text: "My #{Settings.site.short_name}")
        expect(rendered).to have_selector('a[href="/insured/families/brokers?tab=broker"]', text: 'My Broker')
        expect(rendered).to have_selector('a[href="/insured/families/verification?tab=verification"]', text: 'Documents')
        expect(rendered).to have_selector('a[href="/insured/families/inbox?tab=messages"]', text: 'Messages')
      end

      it "should display the info under my account in the side bar" do
        expect(rendered).to have_selector('h4', 'My Account')
        expect(rendered).to have_selector('span', "#{person.first_name} #{person.last_name}")
        expect(rendered).to have_selector('span', "Your household of #{family_members.count}")
      end

      it "should display the list of active household" do
        family_members.each do |family_member|
          expect(rendered).to match(/#{family_member.first_name} #{family_member.last_name}/)
        end
      end

      it "should have a link to manage family button" do
        expect(rendered).to have_selector('a[href="/insured/families/manage_family?tab=family"]', text: 'Manage Family')
      end

      it "doesn't show action needed label" do
        expect(rendered).to_not match(/Action Needed/)
      end
    end
  end

  context "all family members are verified" do
    before :each do
      allow(view).to receive(:enrollment_group_unverified?).and_return(false)
      allow(view).to receive(:verification_needed?).and_return(false)
      render partial: "insured/families/navigation.html.erb"
    end

    it "should match the side bar tabs info on family home page" do
      expect(rendered).to have_selector('a[href="/families/home?tab=home"]', text: "My #{Settings.site.short_name}")
      expect(rendered).to have_selector('a[href="/insured/families/brokers?tab=broker"]', text: 'My Broker')
      expect(rendered).to have_selector('a[href="/insured/families/verification?tab=verification"]', text: 'Documents')
      expect(rendered).to have_selector('a[href="/insured/families/inbox?tab=messages"]', text: 'Messages')
    end

    it "should display the info under my account in the side bar" do
      expect(rendered).to have_selector('h4', 'My Account')
      expect(rendered).to have_selector('span', "#{person.first_name} #{person.last_name}")
      expect(rendered).to have_selector('span', "Your household of #{family_members.count}")
    end

    it "should display the list of active household" do
      family_members.each do |family_member|
        expect(rendered).to match(/#{family_member.first_name} #{family_member.last_name}/)
      end
    end

    it "should have a link to manage family button" do
      expect(rendered).to have_selector('a[href="/insured/families/manage_family?tab=family"]', text: 'Manage Family')
    end

    it "shows action needed label" do
      expect(rendered).to_not match(/Action Needed/)
    end

  end

end
