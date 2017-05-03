module MobileBrokerAgencyData
  shared_context 'broker_agency_data' do
    let!(:broker_role) { FactoryGirl.create(:broker_role) }
    let(:person) { double("person", broker_role: broker_role, first_name: "Brunhilde") }
    let(:user) { double("user", :has_hbx_staff_role? => false, :has_employer_staff_role? => false, :person => person) }
    let(:organization) {
      o = FactoryGirl.create(:employer)
      a = o.primary_office_location.address
      a.address_1 = '500 Employers-Api Avenue'
      a.address_2 = '#555'
      a.city = 'Washington'
      a.state = 'DC'
      a.zip = '20001'
      o.primary_office_location.phone = Phone.new(:kind => 'main', :area_code => '202', :number => '555-9999')
      o.save
      o
    }
    let(:broker_agency_profile) {
      profile = FactoryGirl.create(:broker_agency_profile, organization: organization)
      broker_role.broker_agency_profile_id = profile.id
      profile
    }

    let(:staff_user) { FactoryGirl.create(:user) }
    let(:staff) do
      s = FactoryGirl.create(:person, :with_work_email, :male)
      s.user = staff_user
      s.first_name = "Seymour"
      s.emails.clear
      s.emails << ::Email.new(:kind => 'work', :address => 'seymour@example.com')
      s.phones << ::Phone.new(:kind => 'mobile', :area_code => '202', :number => '555-0000')
      s.save
      s
    end

    let(:staff_user2) { FactoryGirl.create(:user) }
    let(:staff2) do
      s = FactoryGirl.create(:person, :with_work_email, :male)
      s.user = staff_user2
      s.first_name = "Beatrice"
      s.emails.clear
      s.emails << ::Email.new(:kind => 'work', :address => 'beatrice@example.com')
      s.phones << ::Phone.new(:kind => 'work', :area_code => '202', :number => '555-0001')
      s.phones << ::Phone.new(:kind => 'mobile', :area_code => '202', :number => '555-0002')
      s.save
      s
    end

    let (:broker_agency_account) {
      FactoryGirl.build(:broker_agency_account, broker_agency_profile: broker_agency_profile)
    }

    let (:employer_profile) do
      e = FactoryGirl.create(:employer_profile, organization: organization)
      e.broker_agency_accounts << broker_agency_account
      e.save
      e
    end

    before(:each) do
      allow(user).to receive(:has_hbx_staff_role?).and_return(false)
      allow(user).to receive(:has_broker_agency_staff_role?).and_return(false)
      sign_in(user)

      staff.employer_staff_roles << FactoryGirl.create(:employer_staff_role, employer_profile_id: employer_profile.id)
      staff2.employer_staff_roles << FactoryGirl.create(:employer_staff_role, employer_profile_id: employer_profile.id)
    end
  end
end