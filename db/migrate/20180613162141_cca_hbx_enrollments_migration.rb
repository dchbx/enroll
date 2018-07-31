class CcaHbxEnrollmentsMigration < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "cca"

      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/enrollment_migration_status_#{TimeKeeper.datetime_of_record.strftime("%m_%d_%Y_%H_%M_%S")}.csv"
      field_names = %w( employer_name census_emp_id benefit_group_assignment_id enrollment_id status product_id issuer_profile_id benefit_sponsorship_id sponsored_benefit_package_id sponsored_benefit_id)

      logger = Logger.new("#{Rails.root}/log/enrollment_migration_data.log") unless Rails.env.test?
      logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?

      CSV.open(file_name, 'w') do |csv|
        csv << field_names

        # update enrollments to work with new model
        update_hbx_enrollments(csv, logger)

        puts "" unless Rails.env.test?
        puts "Check enrollment_migration_data logs & enrollment_migration_status csv for additional information." unless Rails.env.test?

      end
      logger.info "End of the script" unless Rails.env.test?
    else
      say "Skipping for non-CCA site"
    end
  end

  def self.down
  end

  private

  def self.update_hbx_enrollments(csv, logger)
    ces = CensusEmployee.all.exists(benefit_group_assignments: true)

    @issuer_orga = BenefitSponsors::Organizations::Organization.issuer_profiles
    @carrier_orga = Organization.exists(carrier_profile: true)
    @products = BenefitMarkets::Products::Product.all

    #counters
    total_enrollments = 0
    updated_enrollments = 0


    ces.batch_size(1000).no_timeout.all.each do |ce|
      next unless ce.benefit_sponsorship.present?
      ce.benefit_group_assignments.no_timeout.all.each do |bga|

        benefit_sponsorship_id = nil
        product_id = nil
        issuer_profile_id = nil
        sponsored_benefit_package_id = nil
        sponsored_benefit_id = nil
        rating_area_id = nil

        unless bga.benefit_package_id.present?
          csv << [ce.employer_profile.legal_name, ce.id, bga.id, "no benefit package id", "skipped in current migrartion as there is no benefit package id", product_id, issuer_profile_id, benefit_sponsorship_id, sponsored_benefit_package_id, sponsored_benefit_id]
          next
        end

        enrollments = get_hbx_enrollments(bga)
        next unless enrollments.present?

        enrollments.each do |enrollment|

          next unless new_model_ids_nil?(enrollment)

          total_enrollments = total_enrollments + 1
          begin

            #get plan_id - product_id
            if enrollment.plan.present?
              hios_id = enrollment.plan.hios_id
              plan_active_year = enrollment.plan.active_year
              products = @products.where(hios_id: hios_id)
              product = products.select {|product| product.application_period.min.year == plan_active_year}

              product_id = product.first.id if product.count == 1
            end

            #get carrier_profile_id - issuer_profile_id
            if enrollment.carrier_profile_id.present?
              carrier_profile_id = enrollment.carrier_profile_id
              carrier_profiles = @carrier_orga.where(id: carrier_profile_id)
              carrier_profile_hbx_id = carrier_profiles.first.hbx_id if carrier_profiles.present?
              issuer_profile_id = @issuer_orga.where(hbx_id: carrier_profile_hbx_id).first.id if carrier_profile_hbx_id.present?
            end

            #get benefit_sponsorship_id
            benefit_sponsorship_id = ce.benefit_sponsorship.id

            #get sponsored_benefit_package_id
            sponsored_benefit_package_id = bga.benefit_package_id

            #get sponsored_benefit_id
            if sponsored_benefit_package_id.present?
              benefit_package = bga.benefit_package
              sponsored_benefit = benefit_package.sponsored_benefit_for('health')
              sponsored_benefit_id = sponsored_benefit.id
              rating_area_id = benefit_package.benefit_application.recorded_rating_area_id
            end


            enrollment.update_attributes(product_id: product_id,
                                         issuer_profile_id: issuer_profile_id,
                                         benefit_sponsorship_id: benefit_sponsorship_id,
                                         sponsored_benefit_package_id: sponsored_benefit_package_id,
                                         sponsored_benefit_id: sponsored_benefit_id,
                                         rating_area_id: rating_area_id
            )

            print '.' unless Rails.env.test?
            updated_enrollments = updated_enrollments + 1
            csv << [ce.employer_profile.legal_name, ce.id, bga.id, enrollment.id, "updated", enrollment.product_id, enrollment.issuer_profile_id, enrollment.benefit_sponsorship_id, enrollment.sponsored_benefit_package_id, enrollment.sponsored_benefit_id]

          rescue Exception => e
            print 'F' unless Rails.env.test?
            csv << [ce.employer_profile.legal_name, ce.id, bga.id, enrollment.id, "failed", enrollment.product_id, enrollment.issuer_profile_id, enrollment.benefit_sponsorship_id, enrollment.sponsored_benefit_package_id, enrollment.sponsored_benefit_id]
            logger.error "update failed for HBX Enrollment: #{enrollment.id},
            #{e.inspect}" unless Rails.env.test?
          end
        end
      end
    end
    logger.info " Total #{total_enrollments} enrollments to be migrated" unless Rails.env.test?
    logger.info " #{updated_enrollments} enrollments updated at this point." unless Rails.env.test?
    return true
  end

  def self.new_model_ids_nil? enrollment
    enrollment.sponsored_benefit_id.nil?
  end

  def self.get_hbx_enrollments(bga)
    bga.covered_families.inject([]) do |enrollments, family|
      family.households.each do |household|
        enrollments += household.hbx_enrollments.select do |enrollment|
          enrollment.benefit_group_assignment_id == bga.id
        end.to_a
      end
      enrollments
    end
  end
end