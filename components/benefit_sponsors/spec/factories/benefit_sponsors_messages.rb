FactoryGirl.define do
  factory :benefit_sponsors_message, class: 'BenefitSponsors::Inboxes::Message' do
    subject "phoenix project"
    body    "welcome to the hbx"
  end
end
