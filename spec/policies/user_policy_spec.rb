require "rails_helper"

describe UserPolicy do
  let(:user) { instance_double(User, :person => current_user_person) }

  describe "given a current user with no person" do
    let(:current_user_person) { nil }
    let(:target_user) { instance_double(User) }
    subject { UserPolicy.new(user, target_user) }

    it "is not lockable" do
      expect(subject.lockable?).to be_falsey 
    end

    it "can not reset the password" do
      expect(subject.reset_password?).to be_falsey 
    end
  end

  describe "given:
    - a current user with a person
    - who does not have an hbx_staff_role
  " do
    let(:current_user_person) { instance_double(Person, :hbx_staff_role => nil) }
    let(:user) { instance_double(User, :person => current_user_person) }
    let(:target_user) { instance_double(User) }
    subject { UserPolicy.new(user, target_user) }

    it "is not lockable" do
      expect(subject.lockable?).to be_falsey 
    end

    it "can not reset the password" do
      expect(subject.reset_password?).to be_falsey 
    end
  end

  describe "given:
    - a current user with a person
    - who has an hbx_staff_role
    - has no kind of permission
  " do
    let(:hbx_staff_role) { instance_double(HbxStaffRole, :permission => nil) }

    let(:current_user_person) { instance_double(Person, :hbx_staff_role => hbx_staff_role) }
    let(:user) { instance_double(User, :person => current_user_person) }
    let(:target_user) { instance_double(User) }
    subject { UserPolicy.new(user, target_user) }

    it "is not lockable" do
      expect(subject.lockable?).to be_falsey 
    end

    it "can not reset the password" do
      expect(subject.reset_password?).to be_falsey 
    end
  end

  describe "given:
    - a current user with a person
    - who has an hbx_staff_role
    - has a permission
    - the permission can not lock unlock
    - the permission can not reset password
  " do

    let(:permission) do
      instance_double(
        Permission,
        {
          :can_lock_unlock => false,
          :can_reset_password => false
        }
      )
    end

    let(:hbx_staff_role) { instance_double(HbxStaffRole, :permission => permission ) }

    let(:current_user_person) { instance_double(Person, :hbx_staff_role => hbx_staff_role) }
    let(:user) { instance_double(User, :person => current_user_person) }
    let(:target_user) { instance_double(User) }
    subject { UserPolicy.new(user, target_user) }

    it "is not lockable" do
      expect(subject.lockable?).to be_falsey 
    end

    it "can not reset the password" do
      expect(subject.reset_password?).to be_falsey 
    end
  end

  describe "given:
    - a current user with a person
    - who has an hbx_staff_role
    - has a permission
    - the permission can lock unlock
    - the permission can reset password
  " do

    let(:permission) do
      instance_double(
        Permission,
        {
          :can_lock_unlock => true,
          :can_reset_password => true
        }
      )
    end

    let(:hbx_staff_role) { instance_double(HbxStaffRole, :permission => permission ) }

    let(:current_user_person) { instance_double(Person, :hbx_staff_role => hbx_staff_role) }
    let(:user) { instance_double(User, :person => current_user_person) }
    let(:target_user) { instance_double(User) }
    subject { UserPolicy.new(user, target_user) }

    it "is not lockable" do
      expect(subject.lockable?).to be_truthy
    end

    it "can not reset the password" do
      expect(subject.reset_password?).to be_truthy
    end
  end
end
