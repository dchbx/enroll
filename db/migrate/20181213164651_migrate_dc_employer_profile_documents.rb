class MigrateDcEmployerProfileDocuments < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "dc"

      logger = Logger.new("#{Rails.root}/log/employer_profiles_documents_migration_data.log") unless Rails.env.test?
      logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?

      status = create_profile_document(logger)
      if status
        puts "" unless Rails.env.test?
        puts "Check employer_profiles_documents_migration_data logs for additional information." unless Rails.env.test?
      else
        puts "" unless Rails.env.test?
        puts "Script execution failed" unless Rails.env.test?
      end
      logger.info "End of the script" unless Rails.env.test?
    else
      say "Skipping for non-CCA site"
    end
  end

  def self.down

  end

  private

  def self.create_profile_document(logger)

    say_with_time("Time taken to migrate documents employer profile and organization") do
      Organization.collection.aggregate([ {"$match" => {"employer_profile" => { "$exists" => true }}},
                                          {"$project" => {"documents" => 1, "employer_profile.documents"=>1, "fein" => 1}},
                                          {"$lookup" => {
                                              from: "benefit_sponsors_organizations_organizations",
                                              localField: "fein",
                                              foreignField: "fein",
                                              as: "results"
                                          }},
                                          {"$project" => { "documents" => { "$concatArrays" => [{ "$ifNull" => [ "$employer_profile.documents", []]}, {"$ifNull"=>["$documents", []]}]}, "results.profiles" => 1}},
                                          {"$unwind" => "$documents"},
                                          {"$unwind" => "$results"},
                                          {"$unwind" => "$results.profiles"},
                                          {"$match" => {"results.profiles._type" =>{ "$in" => ["BenefitSponsors::Organizations::FehbEmployerProfile", "BenefitSponsors::Organizations::AcaShopDcEmployerProfile"]}}},
                                          {"$project"=>{_id: "$documents._id", created_at: "$documents.created_at", updated_at: "$documents.updated_at",
                                                        documentable_type: "$results.profiles._type", documentable_id:  "$results.profiles._id", title: "$documents.title",
                                                        creator: "$documents.creator", subject: "$documents.subject", description: "$documents.description", publisher: "$documents.publisher",
                                                        contributor: "$documents.contributor", date: "$documents.date", type: "$documents.type", format: "$documents.format",
                                                        identifier: "$documents.identifier", source: "$documents.source", language:"$documents.language", relation: "$documents.relation",
                                                        coverage: "$documents.coverage", rights: "$documents.rights", tags: "$documents.tags"}},
                                          {"$out"=> "benefit_sponsors_documents_documents"}

                                        ]).each

    end

    say_with_time("Time taken to migrate inbox of employer profile") do

      old_organizations = Organization.unscoped.exists(:employer_profile => true)

      total_organizations = old_organizations.count
      success =0
      failed = 0
      limit_count = 1000


      old_organizations.batch_size(limit_count).no_timeout.each do |old_org|
        begin
         new_profile = new_profile(old_org)
         old_profile = old_org.employer_profile

         build_inbox_messages(old_profile, new_profile)

         raise Exception unless new_profile.valid?
         BenefitSponsors::Organizations::Organization.skip_callback(:create, :after, :notify_on_create)
         BenefitSponsors::Organizations::Profile.skip_callback(:save, :after, :publish_profile_event)
         new_profile.save

         print '.' unless Rails.env.test?
         success = success + 1
        rescue Exception => e
          failed = failed + 1
          print 'F' unless Rails.env.test?
          # TODO
          # logger.error "Migration Failed for Organization HBX_ID: #{old_org.hbx_id},
          # validation_errors:
          # profile - #{new_profile.errors.messages},
          # #{e.inspect}" unless Rails.env.test?
        end
      end

      logger.info " Total #{total_organizations} old organizations for type: employer profile" unless Rails.env.test?
      logger.info " #{failed} organizations failed to migrated to new DB at this point." unless Rails.env.test?
      logger.info " #{success} organizations migrated to new DB at this point." unless Rails.env.test?
      return true
    end

  end

  def self.find_new_organization(old_org)
    BenefitSponsors::Organizations::Organization.where(fein: old_org.fein)
  end

  def self.new_profile(old_org)
    BenefitSponsors::Organizations::Organization.where(fein: old_org.fein).first.employer_profile
  end

  def self.build_inbox_messages(old_profile, new_profile)
    old_profile.inbox.messages.each do |message|
      msg = new_profile.inbox.messages.new(message.attributes.except("_id"))
      msg.body.gsub!("EmployerProfile", new_profile._type.split('::').last)
      msg.body.gsub!(old_profile.id.to_s, new_profile.id.to_s)
    end
  end
end
