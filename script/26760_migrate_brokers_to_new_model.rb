
def initialize_new_profile(old_org, old_profile_params)
  new_profile = BenefitSponsors::Organizations::BrokerAgencyProfile.new(old_profile_params)

  build_documents(old_org, new_profile)
  build_inbox_messages(new_profile)
  build_office_locations(old_org, new_profile)
  return new_profile
end

def build_documents(old_org, new_profile)

  @old_profile.documents.each do |document|
    doc = new_profile.documents.new(document.attributes.except("_id", "_type", "identifier","size"))
    doc.identifier = document.identifier if document.identifier.present?
    BenefitSponsors::Documents::Document.skip_callback(:save, :after, :notify_on_save)
    doc.save!
  end

  old_org.documents.each do |document|
    doc = new_profile.documents.new(document.attributes.except("_id", "_type", "identifier","size"))
    doc.identifier = document.identifier if document.identifier.present?
    BenefitSponsors::Documents::Document.skip_callback(:save, :after, :notify_on_save)
    doc.save!
  end
end

def build_inbox_messages(new_profile)
  @old_profile.inbox.messages.each do |message|
    msg = new_profile.inbox.messages.new(message.attributes.except("_id"))
    msg.body.gsub!("BrokerAgencyProfile", "BenefitSponsorsBrokerAgencyProfile")
    msg.body.gsub!(@old_profile.id.to_s, new_profile.id.to_s)

    new_profile.documents.where(subject: "notice").each do |doc|
      old_emp_docs = @old_profile.documents.where(identifier: doc.identifier)
      old_org_docs = @old_profile.organization.documents.where(identifier: doc.identifier)
      old_document_id = if old_emp_docs.present?
                          old_emp_docs.first.id.to_s
                        elsif old_org_docs.present?
                          old_org_docs.first.id.to_s
                        end
      msg.body.gsub!(old_document_id, doc.id.to_s) if (doc.id.to_s.present? && old_document_id.present?)
    end

  end
end

def build_office_locations(old_org, new_profile)
  old_org.office_locations.each do |office_location|
    new_office_location = new_profile.office_locations.new()
    new_office_location.is_primary = office_location.is_primary
    address_params = office_location.address.attributes.except("_id") if office_location.address.present?
    phone_params = office_location.phone.attributes.except("_id") if office_location.phone.present?
    new_office_location.address = address_params
    new_office_location.phone = phone_params
  end
end

def initialize_new_organization(organization, site)
  json_data = organization.to_json(:except => [:_id, :updated_by_id, :issuer_assigned_id, :version, :versions, :fein, :broker_agency_profile, :office_locations, :is_fake_fein, :is_active, :updated_by, :documents])
  old_org_params = JSON.parse(json_data)
  exempt_organization = BenefitSponsors::Organizations::ExemptOrganization.new(old_org_params)
  exempt_organization.entity_kind = @old_profile.entity_kind.to_sym
  exempt_organization.site = site
  exempt_organization.profiles << [@new_profile]
  return exempt_organization
end

def find_staff_roles
  Person.or({:"broker_role.broker_agency_profile_id" => @old_profile.id},
            {:"broker_agency_staff_roles.broker_agency_profile_id" => @old_profile.id})
end

def link_existing_staff_roles_to_new_profile(person_records_with_old_staff_roles)
  person_records_with_old_staff_roles.each do |person|

    old_broker_role = person.broker_role
    old_broker_agency_staff_role = person.broker_agency_staff_roles.where(broker_agency_profile_id: @old_profile.id).first

    old_broker_role.update_attributes(benefit_sponsors_broker_agency_profile_id: @new_profile.id)
    old_broker_agency_staff_role.update_attributes(benefit_sponsors_broker_agency_profile_id: @new_profile.id) if old_broker_agency_staff_role.present?
  end
end

site = BenefitSponsors::Site.all.where(site_key: :cca).first

old_organizations = Organization.where(:"created_at".gte => Date.new(2018, 7, 12), :"broker_agency_profile" => {:"$exists" => true })

old_organizations.each do |old_org|
  begin
    existing_new_organizations = BenefitSponsors::Organizations::Organization.where(hbx_id: old_org.hbx_id)
    unless existing_new_organizations.blank?
      puts "New Model Organization already exists"
      next
    end

    @old_profile = old_org.broker_agency_profile

    json_data = @old_profile.to_json(:except => [:_id, :entity_kind, :aasm_state_set_on, :inbox, :documents])
    old_profile_params = JSON.parse(json_data)

    @new_profile = initialize_new_profile(old_org, old_profile_params)
    new_organization = initialize_new_organization(old_org, site)

    raise Exception unless new_organization.valid?
    BenefitSponsors::Organizations::Organization.skip_callback(:create, :after, :notify_on_create)
    new_organization.save!

    person_records_with_old_staff_roles = find_staff_roles
    link_existing_staff_roles_to_new_profile(person_records_with_old_staff_roles)
  rescue Exception => e
    puts "Error: #{e.inspect}"
  end
end
