require 'csv'

namespace :reports do
  namespace :shop do

    desc "Identify employer's account information"
    task :employer_information_dc => :environment do
      begin
        csv = CSV.open('NFP_SampleERInfo.csv',"r",:headers =>true, :encoding => 'ISO-8859-1')
        @data= csv.to_a
        miss_match = CSV.open('miss_match_nfp_file.csv',"w",:headers =>true, :encoding => 'ISO-8859-1')
        @data.each do |data_row|
          organization = Organization.where(:hbx_id => data_row["CUSTOMER_CODE"]).first
          poc = Person.where(:'employer_staff_roles.employer_profile_id' =>organization.employer_profile.id,:"employer_staff_roles.is_active" => true).first unless organization.nil?
          if organization.nil? || 
            organization.fein != data_row["TAX_ID"] ||
            organization.dba != data_row["CUSTOMER_NAME"]||
            organization.primary_office_location.address.try(:address_1).upcase !=data_row["B_ADD1"].upcase||
            organization.primary_office_location.address.try(:address_2).upcase !=data_row["B_ADD2"].upcase||
            organization.primary_office_location.address.try(:city).upcase !=data_row["B_CITY"].upcase||
            organization.primary_office_location.address.try(:state).upcase !=data_row["B_STATE"].upcase||
            organization.primary_office_location.address.try(:zip) !=data_row["B_ZIP"]||
            organization.mailing_address.address.try(:address_1).upcase !=data_row["M_ADD1"].upcase|| 
            organization.mailing_address.address.try(:address_2).upcase !=data_row["M_ADD2"].upcase||
            organization.mailing_address.address.try(:city).upcase !=data_row["M_CITY"].upcase||
            organization.mailing_address.address.try(:state).upcase !=data_row["M_STATE"].upcase||
            organization.mailing_address.address.try(:zip).upcase !=data_row["M_ZIP"].upcase||
            organization.primary_office_location.address.try(:mailling_address).try(:phone).try(:full_phone_number)!=data_row["M_PHONE"].upcase||
            poc.try(:name_pfx) != data_row["B_CONTACT_PREFIX"]||
            poc.try(:first_name)   != data_row["B_CONTACT_FNAME"]||
            poc.try(:middle_name)  != data_row["B_CONTACT_MI"]||
            poc.try(:last_name)    != data_row["B_CONTACT_LNAME"]||
            poc.try(:name_sfx)     != data_row["B_CONTACT_SUFFIX"]||
            poc.try(:work_email).try(:address) !=data_row["M_EMAIL"]           

            miss_match << data_row
          end
        end
      rescue Exception => e
        puts "Unable to open file #{e}"
      end 
    end
  end
end