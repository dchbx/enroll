# frozen_string_literal: true

require 'rails_helper'

describe BulkNoticeWorker do
  describe "#peform_async" do

    context "with employees as the audience type" do
      let(:profile) { FactoryBot.create :benefit_sponsors_organizations_aca_shop_dc_employer_profile }
      let(:audience) { profile.organization }
      let!(:user) { FactoryBot.create(:user, :with_hbx_staff_role) }
      let(:bulk_notice) { FactoryBot.create :bulk_notice, user: user, audience_type: 'employees', audience_ids: [audience.id.to_s]}

      before { BulkNoticeWorker.perform_async(audience.id.to_s, bulk_notice.id.to_s) }

      it 'delievered a message with results' do
        skip("is implemented but waiting")
      end

      it 'generates a result for each employee (audience_member)' do
        skip("is implemented but waiting")
      end

    end
  end
end