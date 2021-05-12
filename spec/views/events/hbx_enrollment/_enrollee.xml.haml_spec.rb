# frozen_string_literal: true

require 'rails_helper'
RSpec.describe "app/views/events/shared/_enrollee.xml.haml", dbclean: :after_each do
  let!(:issuer_profile)  { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile) }
  let!(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product,issuer_profile: issuer_profile) }
  let(:person) { FactoryBot.create(:person)}
  let!(:dep_person) { FactoryBot.create(:person)}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let(:hbx_enrollment_member) { FactoryBot.build(:hbx_enrollment_member, applicant_id: family.primary_family_member.id, is_subscriber: true, tobacco_use: 'Y', eligibility_date: TimeKeeper.date_of_record)}
  let!(:family_member) do
    fm = FactoryBot.build(:family_member, person: dep_person, family: family, is_primary_applicant: false, is_consent_applicant: true)
    family.family_members << [fm]
    fm
  end
  let!(:hbx_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      household: family.active_household,
                      family: family,
                      kind: "individual",
                      created_at: Time.now,
                      hbx_enrollment_members: [hbx_enrollment_member],
                      product_id: product.id)
  end
  before :each do
    allow(hbx_enrollment).to receive(:premium_for).and_return(0.0)
  end
  context "ivl enrollment with primary family" do
    before do
      render :partial => "events/shared/enrollee", :collection => hbx_enrollment.hbx_enrollment_members, as: :hbx_enrollment_member, :locals => { :hbx_enrollment => hbx_enrollment, :subscriber => hbx_enrollment.subscriber }
      @doc = Nokogiri::XML(rendered)
    end
    it "should include is_tobacco_user" do
      expect(@doc.xpath("//person_health//is_tobacco_user").text).to eq hbx_enrollment_member.tobacco_use
    end
  end
end
