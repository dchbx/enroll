require 'rails_helper'

module BenefitSponsors
  module Factories
    RSpec.describe Site, type: :model do
      shared_context "params", :shared_context => :metadata do
        let(:params) do
          {
            'site_key'=>'DC',
            'long_name'=>'District of Columbia',
            'short_name'=>'DC',
            'byline'=>'Healthlink',
            'domain_name' => 'dc.gov',
            'owner_organization_attributes'=>{
              'legal_name'=>'District of Columbia HealthLink',
              'profile_attributes'=>{
                'office_locations_attributes'=>{
                  '0'=>{
                    'is_primary'=>'true',
                    'phone_attributes'=>{
                      'kind'=>'main',
                      'area_code'=>'202',
                      'number'=>'2222222'},
                      'address_attributes'=>{
                        'kind'=>'primary',
                        'address_1'=>'2nd St',
                        'address_2'=>'',
                        'city'=>'Washington',
                        'state'=>'DC',
                        'zip'=>'20001'
                      }
                  }
                }
              }
            }
          }
        end
      end

      describe '##for_new' do
        subject { BenefitSponsors::Forms::Site.for_new }
        it 'instantiates a new Site Form' do
          expect(subject).to be_an_instance_of(BenefitSponsors::Forms::Site)
        end

        it 'the Site Form has an Owner Organization' do
          expect(subject.owner_organization).to be_an_instance_of(BenefitSponsors::Forms::ExemptOrganization)
        end
      end

      describe '##for_create', dbclean: :after_each do
        include_context 'params'

        subject { BenefitSponsors::Forms::Site.for_create params }

        it 'instantiates a new Site Form with the correct variables' do
          expect(subject.site_key).to eql('DC')
        end

        it 'has the primary office' do
          expect(subject.owner_organization.profile.office_locations.first.is_primary?).to be_truthy
        end

        it 'creates a new BenfitSponsors::Site when saved' do
          expect { subject.save }.to change { BenefitSponsors::Site.count }.by(1)
        end
      end

      describe '##for_edit', dbclean: :after_each do
        let(:site) { create :benefit_sponsors_site, :as_hbx_profile, :cca }
        subject { BenefitSponsors::Forms::Site.for_edit site.id.to_s }

        it 'loads the existing Site in to the Site Form' do
          expect(subject.long_name).to eql(site.long_name)
        end

        it 'loads the office address too' do
          expect(subject.owner_organization.profile.office_locations.first.address.address_1).to eql(site.owner_organization.profiles.first.office_locations.first.address.address_1)
        end
      end

      describe '##for_update', dbclean: :after_each do
        include_context 'params'

        let(:site) { create :benefit_sponsors_site, :as_hbx_profile, :cca }

        subject { BenefitSponsors::Forms::Site.for_update site.id.to_s }

        it 'loads the existing Site in to the Site Form' do
          expect(subject.long_name).to eql(site.long_name)
        end

        it 'loads the office address too' do
          expect(subject.owner_organization.profile.office_locations.first.address.address_1).to eql(site.owner_organization.profiles.first.office_locations.first.address.address_1)
        end

        context '#updates_attributes' do
          before do
            subject.update_attributes params
            site.reload
          end

          it "updates the db model's long_name" do
            expect(site.long_name).to eql(params['long_name'])
          end

          it "updates the form's long_name" do
            expect(subject.long_name).to eql(params['long_name'])
          end

          it 'updates the office address' do
            expect(subject.owner_organization.profile.office_locations.first.address.address_1).to eql(site.owner_organization.profiles.first.office_locations.first.address.address_1)
          end
        end
      end
    end
  end
end
