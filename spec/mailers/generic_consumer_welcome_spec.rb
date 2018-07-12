require 'rails_helper'

RSpec.describe UserMailer do
  describe 'generic_consumer_welcome' do
    let(:hbx_id) { rand(10000 )}
    let(:email){UserMailer.generic_consumer_welcome('john', hbx_id, 'john@dc.gov')}

    it 'should not allow a reply' do
    	expect(email.from.first).to match(/no-reply@individual.#{Settings.site.domain_name}/)
    end

    it 'should deliver to john' do
    	expect(email.to).to match(['john@dc.gov'])
      expect(email.body).to match(/Dear john/)
    end

    it "should have subject of #{Settings.site.short_name}" do
      expect(email.subject).to match(/#{Settings.site.short_name}/)
    end

    it 'should have body text' do
      expect(email.body).to match(/#{Settings.site.short_name} is strongly committed/)
      expect(email.body).to match(/Your Account/)
      expect(email.body).to match(/Customer Care Center/)
    end
  end
end
