require 'rails_helper'

RSpec.describe FamiliesController do

 context "set_family before every action" do
    
    let(:person) {FactoryGirl.create(:person, :with_family);}
    let(:user) { FactoryGirl.create(:user, :person=>person) }
    let(:user_with_out_person) { FactoryGirl.create(:user, :person=>nil) }

    let!(:person2) {FactoryGirl.create(:person)}
    let!(:family_member2) {FactoryGirl.create(:family_member, family: person.primary_family, person: person2) }

    let(:params) { {family:  person.primary_family.id.to_s } }

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

  end

end
