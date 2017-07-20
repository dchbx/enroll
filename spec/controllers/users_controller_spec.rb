require 'rails_helper'

describe UsersController do

  after :all do
    DatabaseCleaner.clean
  end

  describe ".lockable" do
    let(:permission_yes) { FactoryGirl.create(:permission, can_lock_unlock: true) }
    let(:permission_no) { FactoryGirl.create(:permission, can_lock_unlock: false) }
    let(:admin) { FactoryGirl.create(:user, :with_family, :hbx_staff) }
    let(:hbx_staff_role) { FactoryGirl.create(:hbx_staff_role, person: admin.person) }
    let(:hbx_profile) { FactoryGirl.create(:hbx_profile) }

    context 'When admin is not authorized for lockable then User status can not be changed' do
      let(:user) { FactoryGirl.create(:user, :with_consumer_role) }
      before do
        hbx_staff_role.permission_id = permission_no.id
        hbx_staff_role.save
        sign_in(admin)
        get :lockable, id: user.id
      end
      it { expect(user.locked_at).to be_nil }
      it { expect(response).to redirect_to(user_account_index_exchanges_hbx_profiles_url) }
    end

    context 'When admin is authorized for lockable then User status can be locked' do
      let(:user) { FactoryGirl.create(:user, :with_consumer_role) }
      before do
        hbx_staff_role.permission_id = permission_yes.id
        hbx_staff_role.save
        sign_in(admin)
        get :lockable, id: user.id
      end

      subject(:result) { User.find(user.id) }
      it { expect(result.locked_at).not_to be_nil }
      it { expect(response).to redirect_to(user_account_index_exchanges_hbx_profiles_url) }
    end

    context 'When admin is authorized and User status is locked then it should be unlocked' do
      let(:user) { FactoryGirl.create(:user, :with_consumer_role) }
      before do
        hbx_staff_role.permission_id = permission_yes.id
        hbx_staff_role.save
        user.lock!
        sign_in(admin)
        get :lockable, id: user.id
      end

      subject(:result) { User.find(user.id) }
      it { expect(result.locked_at).to be_nil }
      it { expect(response).to redirect_to(user_account_index_exchanges_hbx_profiles_url) }
    end
  end
end
