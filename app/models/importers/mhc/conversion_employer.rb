module Importers::Mhc
  class ConversionEmployer < Importers::ConversionEmployer

    # CARRIER_MAPPING = {
    #   "bmc healthnet plan"=>"BMCHP",
    #   "fallon community health plan"=>"FCHP",
    #   "health new england"=>"HNE",
    #   "neighborhood health plan" => "NHP",
    #   "harvard pilgrim health care" => "HPHC",
    #   "boston medical center health plan" => "BMCHP",
    #   "blue cross blue shield ma" => "BCBS"
    # }

    attr_accessor :fein,
                  :assigned_employer_id,
                  :sic_code,
                  :primary_location_county_fips,
                  :primary_location_zip,
                  :mailing_location_zip

    def primary_location_zip=(val='')
      @primary_location_zip= prepend_zeros(val.to_i.to_s,5)
    end

    def mailing_location_zip=(val='')
      @mailing_location_zip= prepend_zeros(val.to_i.to_s,5)
    end

    def fein=(val)
      @fein = prepend_zeros(val.to_s.gsub('-', '').strip, 9)
    end

    def build_primary_address
      Address.new(
          :kind => "primary",
          :address_1 => primary_location_address_1,
          :address_2 => primary_location_address_2,
          :city =>  primary_location_city,
          :state => primary_location_state,
          :county => primary_location_county,
          :location_state_code => primary_location_county_fips,
          :zip => primary_location_zip
      )
    end
  end
end