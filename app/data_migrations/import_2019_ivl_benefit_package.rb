# require File.join(Rails.root, "lib/mongoid_migration_task")

class Import2019IvlBenefitPackage < MongoidMigrationTask

  def migrate
    puts "::: Creating IVL 2019 benefit packages :::" unless Rails.env.test?
    # BenefitPackages - HBX 2019
    hbx = HbxProfile.current_hbx

    # create benefit package and benefit_coverage_period for 2019
    bc_period_2018 = hbx.benefit_sponsorship.benefit_coverage_periods.select { |bcp| bcp.start_on.year == 2018 }.first
    unless bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp.start_on.year == 2019 }
      bc_period = bc_period_2018.dup
      bc_period.title = "Individual Market Benefits 2019"
      bc_period.start_on = bc_period_2018.start_on.next_year
      bc_period.end_on = bc_period_2018.end_on.next_year
      bc_period.open_enrollment_start_on = bc_period_2018.open_enrollment_start_on.next_year
      bc_period.open_enrollment_end_on = bc_period_2018.open_enrollment_end_on.next_year

      bs = hbx.benefit_sponsorship
      bs.benefit_coverage_periods << bc_period
      bs.save
    end
  end
end