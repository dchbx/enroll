# module Importers::Mhc
#   class ConversionEmployerUpdate < ConversionEmployer
#
#     def initialize(opts = {})
#       super(opts)
#     end
#
#     # covered scenarios
#     # if broker is hired/terminated, then updated_at column in employer_profile model is changed.
#     # if office locations is updated, then updated_at column in organization model is changed.
#     # if employer info is updated, then updated_at column in employer_profile model is changed.
#     # if broker_agency_profile info is updated, then updated_at column in broker_agency_profile model is changed.
#
#     def has_data_not_changed_since_import
#       has_organization_info_changed?
#       has_employer_info_changed?
#       has_office_locations_changed?
#       has_broker_agency_profile_info_changed?
#     end
#
#     def find_organization
#       return nil if fein.blank?
#       Organization.where(:fein => fein).first
#     end
#
#     def employer_profile
#       find_organization.try(:employer_profile)
#     end
#
#     def broker_agency_profile
#       employer_profile.try(:broker_agency_profile)
#     end
#
#     def has_organization_info_changed?
#       organization = find_organization
#       if organization.present? && organization.updated_at > organization.created_at
#         errors.add(:organization, "import cannot be done as organization info was updated on #{organization.updated_at}")
#       end
#     end
#
#     def has_employer_info_changed?
#       if employer_profile.present? && employer_profile.updated_at > employer_profile.created_at
#         errors.add(:employer_profile, "import cannot be done as employer updated the info on #{employer_profile.updated_at}")
#       end
#     end
#
#     def has_broker_agency_profile_info_changed?
#       if broker_agency_profile.present? && broker_agency_profile.updated_at > broker_agency_profile.created_at
#         errors.add(:broker_agency_profile, "import cannot be done as broker agency profile was updated on #{employer_profile.updated_at}")
#       end
#     end
#
#     def has_office_locations_changed?
#       organization = find_organization
#       if organization.present?
#         organization.office_locations.each do |office_location|
#           address = office_location.try(:address)
#           if address.present? && address.updated_at.present? && address.created_at.present? && address.updated_at > address.created_at
#             errors.add(:organization, "import cannot be done as office location was updated on #{address.updated_at}.")
#           end
#         end
#       end
#     end
#
#     def save
#       organization = find_organization
#       begin
#         if organization.blank?
#           errors.add(:fein, "employer don't exists with given fein")
#         end
#         has_data_not_changed_since_import
#
#         if errors.empty?
#           puts "Processing Update #{fein}---Data Sheet# #{legal_name}---Enroll App# #{organization.legal_name}" unless Rails.env.test?
#           organization.legal_name = legal_name
#           organization.dba = dba
#           organization.office_locations = map_office_locations
#
#           if broker_npn.present?
#             broker_exists_if_specified
#             br = BrokerRole.by_npn(broker_npn).first
#             if br.present? && organization.employer_profile.broker_agency_accounts.where(:writing_agent_id => br.id).blank?
#               organization.employer_profile.broker_agency_accounts = assign_brokers
#             end
#           end
#
#           broker = find_broker
#           general_agency = find_ga
#
#           if broker.present? && general_agency.present?
#
#             general_agency_account = organization.employer_profile.general_agency_accounts.where({
#               :general_agency_profile_id => general_agency.id,
#               :broker_role_id => broker.id
#               }).first
#
#             if general_agency_account.present?
#
#               organization.employer_profile.general_agency_accounts.each do |account|
#                 if (account.id != general_agency_account.id && account.active?)
#                   account.terminate! if account.may_terminate?
#                 end
#               end
#
#               general_agency_account.update_attributes(:aasm_state => 'active') if general_agency_account.inactive?
#             else
#               if new_account = assign_general_agencies.first
#                 organization.employer_profile.general_agency_accounts.each{|ac| ac.terminate! if ac.may_terminate? }
#                 organization.employer_profile.general_agency_accounts << new_account
#               end
#             end
#           end
#           update_result = organization.save
#         else
#           update_result = false # if there are errors, then return false.
#         end
#
#       rescue Mongoid::Errors::UnknownAttribute
#         organization.employer_profile.plan_years.each do |py|
#           py.benefit_groups.each{|bg| bg.unset(:_type) }
#         end
#         update_result = errors.empty? && organization.save
#       rescue Exception => e
#         puts "FAILED.....#{e.to_s}"
#       end
#
#       begin
#         if update_result
#           update_poc(organization.employer_profile)
#         end
#       rescue Exception => e
#         puts "FAILED.....#{e.to_s}"
#       end
#
#       if organization
#         propagate_errors(organization)
#       end
#
#       return update_result
#     end
#   end
# end
