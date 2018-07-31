module BenefitSponsors
  class CoverageAgeCalculator
    def calc_coverage_age_for(member, product, coverage_start_date, eligibility_dates, previous_product)
      coverage_elig_date = eligibility_dates[member.member_id]
      coverage_as_of_date = if (!previous_product.blank?) && (product.id == previous_product.id) && (!coverage_elig_date.blank?)
                              coverage_elig_date
                            else
                              coverage_start_date
                            end
      before_factor = if (coverage_as_of_date.month < member.dob.month)
                        -1
                      elsif ((coverage_as_of_date.month == member.dob.month) && (coverage_as_of_date.day < member.dob.day))
                        -1
                      else
                        0
                      end
      coverage_as_of_date.year - member.dob.year + (before_factor)
    end
  end
end
