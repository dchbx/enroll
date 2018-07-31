module BenefitSponsors
  module Services
    class SiteService
      def initialize(params = {})
        @factory_class = BenefitSponsors::Factories::Site
        @params = params
      end

      def build(attrs={})
        @factory_class.build
      end

      def store!(form)
        BenefitSponsors::Factories::Site.call(form_attributes_to_params(form))
      end

      def form_params_to_attributes(form, site)
        model_attributes = {
          site_key: form.site_key,
          byline: form.byline,
          long_name: form.long_name,
          short_name: form.short_name,
          domain_name: form.domain_name,
          owner_organization: {
            legal_name: form.owner_organization.legal_name,
            profiles: [{
              office_locations: form.owner_organization.profile.office_locations.map do |location|
                {
                  is_primary: location.is_primary,
                  phone: location.phone.attributes.slice(:kind, :area_code, :number, :extension),
                  address: location.address.attributes.slice(:kind, :address_1, :address_2, :city, :state, :zip),
                }
              end
            }]
          }
        }
        site.assign_attributes(model_attributes)
      end

      def attributes_to_form_params(site, form)
        form.attributes = {
          id: site.persisted? ? site.id : nil,
          site_key: site.site_key,
          byline: site.byline,
          long_name: site.long_name,
          short_name: site.short_name,
          domain_name: site.domain_name,
          owner_organization: {
            legal_name: site.owner_organization.legal_name,
            profile: {
              office_locations: site.owner_organization.profiles.first.office_locations.map do |location|
                {
                  is_primary: location.is_primary,
                  phone: location.phone.attributes,
                  address: location.address.attributes
                }
              end
            }
          }
        }
        form
      end

      # Load the peristance entities and use them to populate the form
      # attributes.
      #
      # Normally this method would contain only a persistence lookup and
      # attribute mappings.
      # In my case I have to figure out which form subclass I should be using.
      # @param form [Object] The form for which to load the parameters.
      # @return [Object] A form object containing the loaded parameters.
      def load_form_params_from_resource(form)
        site = find_model_by_id(form.id)
        attributes_to_form_params(site, form)
      end

      def find_model_by_id(id)
        BenefitSponsors::Site.find(id)
      end

      def update(form)
        site = find_model_by_id(form.id)
        form_params_to_attributes(form, site)
        store(form, site)
      end

      def save(form)
        office_locations = form.owner_organization.profile.office_locations.map do |office_location|
          BenefitSponsors::Locations::Factories::OfficeLocation.call is_primary: office_location.is_primary,
            phone_attributes: office_location.phone.attributes,
            address_attributes: office_location.address.attributes
        end
        profile = BenefitSponsors::Organizations::Factories::HbxProfile.call(office_locations)
        owner_organization = BenefitSponsors::Organizations::Factories::OwnerOrganization.call(legal_name: form.owner_organization.legal_name, profile: profile)
        profile.organization = owner_organization
        site = BenefitSponsors::Factories::Site.call site_key: form.site_key,
          byline: form.byline,
          long_name: form.long_name,
          short_name: form.short_name,
          domain_name: form.domain_name,
          owner_organization: owner_organization

        owner_organization.site = site

        valid_according_to_factory = BenefitSponsors::Factories::Site.validate(site)
        unless valid_according_to_factory
          map_errors_for(site, onto: form)
          return false
        end
        save_successful = site.save
        unless save_successful
          map_errors_for(site, onto: form)
          return false
        end
        true
      end

      def store(form, site)
        if site.save
          true
        else
          map_errors_for(site, onto: form)
          false
        end
      end

      def map_errors_for(site, onto:)
        site.owner_organization.errors.each do |att, err|
          onto.owner_organization.errors.add(att, err)
        end

        site.owner_organization.profiles.first.errors.each do |att, err|
          onto.owner_organization.profile.errors.add(att, err)
        end

        site.owner_organization.profiles.first.office_locations.each_with_index do |location, index|
          form_location = onto.owner_organization.profile.office_locations[index]

          location.errors.each do |att, err|
            form_location.errors.add(att, err)
          end

          location.phone.errors.each do |att, err|
            form_location.phone.errors.add(att, err)
          end

          location.address.errors.each do |att, err|
            form_location.address.errors.add(att, err)
          end
        end

        site.errors.each do |att, err|
          onto.errors.add(att, err)
        end
      end
    end
  end
end
