require 'rails_helper'

RSpec.describe FamiliesController do

 context "set_family before every action" do

    let(:person) {FactoryBot.create(:person, :with_family)}
    let(:user) { FactoryBot.create(:user, :person => person) }
    let(:user_with_out_person) { FactoryBot.create(:user, :person => nil) }

    let(:person_without_family) { FactoryBot.create(:person) }
    let(:user_2) { FactoryBot.create(:user, :person => person_without_family) }

    let(:person_with_hbx_staff_role) { FactoryBot.create(:person, :with_hbx_staff_role)}
    let(:hbx_staff_user) { FactoryBot.create(:user, :person => person_with_hbx_staff_role) }

    let!(:person2) {FactoryBot.create(:person)}
    let!(:family_member2) {FactoryBot.create(:family_member, family: person.primary_family, person: person2) }

    let(:params) { {family:  person.primary_family.id.to_s } }
    let(:qle) { FactoryBot.create(:qualifying_life_event_kind) }

    it "return when @person is nil" do
      sign_in(user_with_out_person)
      expect(subject).to receive(:log) do |msg, severity|
        expect(severity[:severity]).to eq('error')
        expect(msg[:message]).to eq('Application Exception - person required')
      end
      expect(subject).to receive(:redirect_to).with("/saml/logout")
      subject.instance_eval{set_family}
    end

    it "assign primary family to @family if person has primary_family" do
      allow(subject).to receive(:params).and_return(params)
      sign_in(user)
      subject.instance_eval{set_family}
      expect(params[:family]).to eq(person.primary_family.id.to_s)
    end

    it "finds family and assign to @family if family_member person doesn't have primary applicant" do
      allow(subject).to receive(:params).and_return(params)
      sign_in(user)
      subject.instance_eval{set_family}
      expect(person2.families.first).to eq(Family.find(params[:family]))
    end

    it "should redirect to exchange/profiles if family is not present and no params and person is hbx_staff" do
      sign_in(hbx_staff_user)
      expect(subject).to receive(:redirect_to).with("/exchanges/hbx_profiles")
      subject.instance_eval{set_family}
    end

    it "should redirect to root if family is not present and no params" do
      sign_in(user_2)
      expect(subject).to receive(:redirect_to).with(root_path)
      subject.instance_eval{set_family}
    end

    it "qle market kind should be shop" do
      expect(qle.market_kind).to eq "shop"
    end
  end
end