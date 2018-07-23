families = Family.where(:"households.hbx_enrollments" => {:$elemMatch => {
  :created_at.gt => Date.new(2018,7,11)
  }})

families.each do |family|
  enrollments = family.active_household.hbx_enrollments.where({
    :created_at.gt => Date.new(2018,7,11)
    })

  enrollments.each do |enrollment|

    benefit_package = enrollment.sponsored_benefit_package
    sponsored_benefit_id = enrollment.sponsored_benefit_id
    sponsored_benefit_allowed_ids = benefit_package.sponsored_benefits.map(&:id)

    if !sponsored_benefit_allowed_ids.include?(sponsored_benefit_id)
      enrollment.update_attributes!({
        sponsored_benefit_id: benefit_package.sponsored_benefits.first.id
      })
      puts "Fixed #{enrollment.hbx_id}"
    end
  end
end