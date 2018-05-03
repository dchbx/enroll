require 'rails_helper'

describe Announcement, dbclean: :after_each do
  describe ".new" do
    let(:valid_params) do
      {
        content: "test msg",
        start_date: TimeKeeper.date_of_record - 10.days,
        end_date: TimeKeeper.date_of_record + 10.days,
        audiences: ['Employer']
      }
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(Announcement.new(**params).save).to be_falsey
      end
    end

    context "with no content" do
      let(:params) {valid_params.except(:content)}

      it "should fail validation" do
        expect(Announcement.create(**params).errors[:content].any?).to be_truthy
      end
    end

    context "with no start_date" do
      let(:params) {valid_params.except(:start_date)}

      it "should fail validation" do
        expect(Announcement.create(**params).errors[:start_date].any?).to be_truthy
      end
    end

    context "with no end_date" do
      let(:params) {valid_params.except(:end_date)}

      it "should fail validation" do
        expect(Announcement.create(**params).errors[:end_date].any?).to be_truthy
      end
    end

    context "with no audiences" do
      let(:params) {valid_params.except(:audiences)}

      it "should fail validation" do
        expect(Announcement.create(**params).errors[:base].any?).to be_truthy
      end

      it "should get alert msg" do
        expect(Announcement.create(**params).errors[:base]).to include "Please select at least one Audience"
      end
    end

    context "end date old than today" do
      let(:params) do
        valid_params[:end_date] = TimeKeeper.date_of_record - 1.days
        valid_params
      end

      it "should fail validation" do
        expect(Announcement.create(**params).errors[:base].any?).to be_truthy
      end

      it "should get alert msg" do
        expect(Announcement.create(**params).errors[:base]).to include "End Date should be later than today"
      end
    end

    context "end date before start date" do
      let(:params) do
        valid_params[:end_date] = TimeKeeper.date_of_record - 20.days
        valid_params
      end

      it "should fail validation" do
        expect(Announcement.create(**params).errors[:base].any?).to be_truthy
      end

      it "should get alert msg" do
        expect(Announcement.create(**params).errors[:base]).to include "End Date should be later than Start date"
      end
    end

    context "with all valid arguments" do
      let(:params) {valid_params}
      let(:announcement) {Announcement.new(**params)}

      it "should save" do
        expect(announcement.save!).to be_truthy
      end
    end

    context "context with space" do
      let(:params) do
        valid_params[:content] = " test msg   "
        valid_params
      end

      it "should update_content" do
        expect(Announcement.create(**params).content).to eq "test msg"
      end
    end
  end

  describe "instance method" do
    it "audiences_for_display" do
      audiences = ['Employer', 'Employee']
      announcement = FactoryGirl.create(:announcement, audiences:audiences)
      expect(announcement.audiences_for_display).to eq audiences.join(',')
    end

    it "update_audiences" do
      audiences = ['Employer', 'Employee', '']
      announcement = FactoryGirl.create(:announcement, audiences:audiences)
      expect(announcement.audiences).to eq ['Employer', 'Employee']
    end
  end

  describe "class method" do
    context "get_announcements_by_portal" do
      let(:person) { FactoryGirl.create(:person) }
      let(:user) { FactoryGirl.create(:user, person: person) }
      before :each do
        Announcement.destroy_all
        Announcement::AUDIENCE_KINDS.each do |kind|
          FactoryGirl.create(:announcement, content: "msg for #{kind}", audiences: [kind])
        end
      end

      it "when employer_staff_role" do
        expect(Announcement.get_announcements_by_portal("dc.org/employers/employer_profiles")).to eq ["msg for Employer"]
      end

      it "when employee_role" do
        allow(person).to receive(:has_active_employee_role?).and_return true
        expect(Announcement.get_announcements_by_portal("dc.org/employee", person)).to eq ["msg for Employee"]
      end

      it "when has active_employee_roles, but without employee_role role" do
        allow(person).to receive(:has_active_employee_role?).and_return true
        expect(Announcement.get_announcements_by_portal("dc.org/employee", person)).to eq ["msg for Employee"]
      end

      it "when visit families/home with active_employee_role and active_consumer_role" do
        allow(person).to receive(:has_active_employee_role?).and_return true
        allow(person).to receive(:is_consumer_role_active?).and_return true
        expect(Announcement.get_announcements_by_portal("dc.org/families/home", person)).to eq ["msg for Employee", "msg for IVL"]
      end

      it "when broker_role" do
        expect(Announcement.get_announcements_by_portal("dc.org/broker_agencies")).to eq ["msg for Broker"]
      end

      it "when consumer_role" do
        allow(person).to receive(:is_consumer_role_active?).and_return true
        expect(Announcement.get_announcements_by_portal("dc.org/consumer", person)).to eq ["msg for IVL"]
      end

      it "when general_agency_staff" do
        expect(Announcement.get_announcements_by_portal("dc.org/general_agencies")).to eq ["msg for GA"]
      end

      context "when broker_role and consumer_role" do
        it "with employer portal" do
          expect(Announcement.get_announcements_by_portal("dc.org/employers")).to eq []
        end

        it "with consumer portal" do
          allow(person).to receive(:is_consumer_role_active?).and_return true
          expect(Announcement.get_announcements_by_portal("dc.org/consumer_role", person)).to eq ["msg for IVL"]
        end

        it "with broker agency portal" do
          expect(Announcement.get_announcements_by_portal("dc.org/broker_agencies")).to eq ["msg for Broker"]
        end
      end
    end
  end
end
