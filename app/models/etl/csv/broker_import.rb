# frozen_string_literal: true

module Etl
  module Csv
    class BrokerImport < Etl::Csv::Base
      include Mongoid::Document

      PROVIDER_TYPE_KINDS = %w[broker].freeze
      PRACTICE_AREA_KINDS = {
        "Small Business Insurance Only" => "shop",
        "Individual and Family Insurance Only" => "individual",
        "Both" => "both"
      }.freeze
      NAME_SUFFIX_KINDS = %w[jr sr ii iii iv clu ltcp cfp mhsa chfc].freeze

      ORDERED_COLUMN_NAMES = %w[
          npn
          created_date
          provider_type
          provider_name
          email
          web_url
          organization_name
          organization_type
          practice_area
          languages
          fax_number
          app_suite
          address_1
          address_2
          city
          state
          zip_code
          latitude
          longitude
          direct_phone
          mobile_phone
          work_phone
          work_phone_extension
        ].freeze

      def parse_row(row)
        {
          organization_name: parse_text(row["organization_name"]),
          organization_type: parse_text(row["organization_type"]),

          provider_name: parse_person_name(row["provider_name"]),
          npn: parse_text(row["npn"]),
          email: parse_text(row["email"]),
          web_url: parse_text(row["web_url"]),
          address_1: parse_text(row["address_1"]),
          address_2: parse_text(row["address_2"]),
          app_suite: parse_text(row["app_suite"]),
          city: parse_text(row["city"]),
          state: parse_text(row["state"]),
          zip_code: parse_text(row["zip_code"]),

          direct_phone: parse_phone_number(row["direct_phone"]),
          mobile_phone: parse_phone_number(row["mobile_phone"]),
          work_phone: parse_phone_number(row["work_phone"]),
          work_phone_extension: parse_text(row["work_phone_extension"]),
          fax_number: parse_phone_number(row["fax_number"]),

          provider_type: parse_text(row["provider_type"].to_s.downcase),
          practice_area: parse_practice_area(row["practice_area"]),
          languages: parse_language(row["languages"]),

          latitude: parse_number(row["latitude"]),
          longitude: parse_number(row["longitude"])
          # created_date:           parse_date(row["created_date"])
        }
      end

      def map_attributes(record)
        add_or_update_broker_role(record)
      end

      def add_or_update_broker_role(record)
        broker_role = BrokerRole.find_by_npn(record[:npn]) #  || BrokerRole.new
        person = nil
        person = if broker_role
                   broker_role.person
                 else
                   Person.new
                 end

        # built_broker_role = assign_broker_role_attributes(broker_role, record)
        # built_broker_role.save

        person = assign_broker_role_attributes(person, record)
        person.save!

        built_broker_role = person.broker_role

        broker_agency_profile = built_broker_role.broker_agency_profile || BrokerAgencyProfile.new
        built_broker_agency_profile = assign_broker_agency_profile_attributes(broker_agency_profile, record)
        built_broker_agency_profile.save!

        if built_broker_agency_profile.primary_broker_role.blank?
          built_broker_agency_profile.primary_broker_role = built_broker_role
          built_broker_agency_profile.save!
        end

        if built_broker_role.broker_agency_profile.blank?
          built_broker_role.broker_agency_profile = built_broker_agency_profile
          built_broker_role.save!
        end

        built_broker_role
      end

      def assign_broker_role_attributes(person, record)
        fax     = Phone.new(kind: "fax", full_phone_number: record[:fax_number])
        mobile  = Phone.new(kind: "mobile", full_phone_number: record[:mobile_phone])
        direct  = Phone.new(kind: "work", full_phone_number: record[:direct_phone])

        phones = [fax, mobile, direct].select { |kind| kind.full_phone_number.present? }
        emails = [Email.new(kind: "work", address: record[:email])]

        person.assign_attributes(
          {
            first_name: record[:provider_name][:first_name],
            middle_name: record[:provider_name][:middle_name],
            last_name: record[:provider_name][:last_name],
            name_sfx: record[:provider_name][:name_suffix],
            phones: phones,
            emails: emails
          }
        )
        person.save!

        person.broker_role = BrokerRole.new unless person.broker_role.present?

        person.broker_role.assign_attributes(
          {
            npn: record[:npn],
            provider_kind: record[:provider_type],
            market_kind: record[:practice_area],
            languages_spoken: record[:languages],
            accept_new_clients: true,
            aasm_state: "active"
          }
        )

        person
      end

      def assign_broker_agency_profile_attributes(broker_agency_profile, record)
        if broker_agency_profile.organization.blank?
          office_location = OfficeLocation.new(
            address: Address.new(
              kind: "work",
              address_1: record[:address_1],
              address_2: record[:address_2],
              address_3: record[:app_wuite],
              city: record[:city],
              state: record[:state],
              zip: record[:zip_code]
            ),
            phone: Phone.new(
              kind: "work",
              full_phone_number: record[:work_phone] || record[:direct_phone],
              extension: record[:work_phone_extension]
            ),
            is_primary: true
          )

          fein = get_next_fein

          organization = Organization.new(
            legal_name: record[:organization_name] || "#{record[:provider_name][:first_name]} #{record[:provider_name][:last_name]}",
            fein: fein,
            home_page: record[:web_url],
            office_locations: [office_location]
          )

          broker_agency_profile = organization.build_broker_agency_profile(
            market_kind: record[:practice_area],
            entity_kind: "s_corporation",
            accept_new_clients: true,
            aasm_state: "is_approved"
          )
        end

        raise StandardError, "BrokerAgency is invalid for NPN: #{record[:npn]}" unless broker_agency_profile.valid?
        raise StandardError, "BrokerAgency organization is invalid for NPN: #{record[:npn]}: #{broker_agency_profile.organization.errors.full_messages.inspect}" unless broker_agency_profile.organization.valid?
        broker_agency_profile
      end

      def get_next_fein
        seed = 999_990_001

        org = Organization.unscoped.order(:fein.desc).limit(1).first
        db_max_fein = org.fein.to_i
        next_fein = db_max_fein + 1

        [seed, next_fein].max
      end

      def ordered_column_names
        ORDERED_COLUMN_NAMES
      end

      def parse_practice_area(cell)
        return nil unless cell.present?

        practice_area = parse_text(cell)
        key = PRACTICE_AREA_KINDS[practice_area]

        raise "Unknown practice_area: #{practice_area}" if key.blank?
        key
      end

      def parse_person_name(cell)
        return nil unless cell.present?
        full_name = parse_text(cell).gsub(",", "").gsub(".", "").split

        case full_name.size
        when 2
          {first_name: full_name[0], last_name: full_name[1]}
        when 3
          if NAME_SUFFIX_KINDS.include?(full_name[2].downcase)
            {first_name: full_name[0], last_name: full_name[1], name_sfx: full_name[2]}
          else
            {first_name: full_name[0], middle_name: full_name[1], last_name: full_name[2]}
          end
        when 4
          if NAME_SUFFIX_KINDS.include?(full_name[3].downcase)
            {first_name: full_name[0], middle_name: full_name[1], last_name: full_name[2], name_sfx: full_name[3]}
          else
            {first_name: "#{full_name[0]} #{full_name[1]}", middle_name: full_name[2], last_name: full_name[3]}
          end
        end
      end

      def parse_language(cell)
        return nil unless cell.present?
        languages = parse_text(cell).split(",")
      end

    end
  end
end
