require "rails_helper"

describe ConsumerRolePolicy do
  subject { described_class }
  let(:consumer_role) { FactoryGirl.create(:consumer_role) }
  let(:consumer_person) { FactoryGirl.create(:person, :with_consumer_role) }
  let(:broker_person) { FactoryGirl.create(:person, :with_broker_role) }
  let(:assister_person) { FactoryGirl.create(:person, :with_assister_role) }
  let(:csr_person) { FactoryGirl.create(:person, :with_csr_role) }
  let(:employee_person) { FactoryGirl.create(:person, :with_employee_role) }

  permissions :privacy? do
    it "grants access when consumer" do
      expect(subject).to permit(FactoryGirl.build(:user, :consumer, person: consumer_person), ConsumerRole)
    end

    it "grants access when broker" do
      expect(subject).to permit(FactoryGirl.build(:user, :broker, person: broker_person), ConsumerRole)
    end

    it "grants access when assister" do
      expect(subject).to permit(FactoryGirl.build(:user, :assister, person: assister_person), ConsumerRole)
    end

    it "grants access when csr" do
      expect(subject).to permit(FactoryGirl.build(:user, :csr, person: csr_person), ConsumerRole)
    end

    it "grants access when user without roles" do
      expect(subject).to permit(User.new, ConsumerRole)
    end

    it "denies access when employee" do
      expect(subject).not_to permit(FactoryGirl.build(:user, :employee, person: employee_person), ConsumerRole)
    end

    it "denies access when employer_staff" do
      expect(subject).not_to permit(FactoryGirl.build(:user, :employer_staff), ConsumerRole)
    end
  end

  permissions :edit? do
    let(:user) {FactoryGirl.create(:user, :consumer)}
    let(:person) { FactoryGirl.build(:person) }
    let(:hbx_staff_person) { FactoryGirl.create(:person, :with_hbx_staff_role) }

    it "grants access when hbx_staff" do
      expect(subject).to permit(FactoryGirl.build(:user, :hbx_staff, person: hbx_staff_person), consumer_role)
    end

    it "denies access when normal user" do
      expect(subject).not_to permit(User.new, consumer_role)
    end

    context "consumer" do
      before :each do
        allow(user).to receive(:person).and_return person
      end

      it "grants access" do
        allow(person).to receive(:consumer_role).and_return consumer_role
        expect(subject).to permit(user, consumer_role)
      end

      it "denies access" do
        allow(person).to receive(:consumer_role).and_return ConsumerRole.new
        expect(subject).not_to permit(user, consumer_role)
      end
    end
  end
end
