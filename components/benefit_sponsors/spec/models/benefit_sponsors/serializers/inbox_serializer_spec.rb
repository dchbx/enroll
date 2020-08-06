# frozen_string_literal: true

require 'spec_helper'

module BenefitSponsors
  RSpec.describe Serializers::InboxSerializer do

    describe '.unread_messages_count', dbclean: :after_each do
      let(:site) do
        FactoryBot.create(:benefit_sponsors_site, :with_owner_exempt_organization, :with_benefit_market, site_key: :cca)
      end
      let(:organization) do
        FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site)
      end
      let(:inbox) { FactoryBot.create(:benefit_sponsors_inbox, :with_message, recipient: organization.employer_profile)}

      let(:inbox_serializer) { Serializers::InboxSerializer.new(inbox) }

      it "has the correct number of unread messages" do
        expect(inbox_serializer.unread_messages_count).to eq(2)
      end
    end

  end
end
