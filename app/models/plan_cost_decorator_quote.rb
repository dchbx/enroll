class PlanCostDecoratorQuote < PlanCostDecorator


  def add_premiums(combined_family, reference_date)
    roster_premium = Hash.new{|h,k| h[k]=0.00}
    combined_family.keys.each {|member|
      age = combined_family[member]
      premium = Caches::PlanDetails.lookup_rate(__getobj__.id, reference_date, age)
      roster_premium[member.employee_relationship] += premium
   }
    roster_premium
  end

  def add_members(combined_family)
     members.each {|member|
       combined_family[member] = member.age_on(benefit_group.quote.start_on) if large_family_factor(member) > 0.0 
     }

  end

  class << self

    def elected_plans_cost_bounds plans, relationship_benefits, roster_premiums
      bounds = {
        carrier_low: Hash.new{|h,k| h[k] = 999999},
        carrier_high: Hash.new{|h,k| h[k] = 0},
        metal_low: Hash.new{|h,k| h[k] = 999999},
        metal_high: Hash.new{|h,k| h[k] = 0},

        carrier_low_plan: Hash.new,
        carrier_high_plan: Hash.new,
        metal_low_plan: Hash.new,
        metal_high_plan: Hash.new,
      }
      #employer_premiums={}
      plans.each{|plan|
        cost = 0
        premiums = roster_premiums[plan.id.to_s]
        premiums.each {|kind, premium|
          cost += relationship_benefits.detect{|rb| rb.relationship == kind}.premium_pct * premium
        }
        cost = (cost/100).ceil
        #employer_premiums[plan.id.to_s] = cost
        carrier = plan.carrier_profile.abbrev

        bounds[:carrier_low_plan][carrier] = plan.id if cost < bounds[:carrier_low][carrier]
        bounds[:carrier_high_plan][carrier] = plan.id if cost > bounds[:carrier_high][carrier]
        bounds[:carrier_low][carrier] = cost if cost < bounds[:carrier_low][carrier]
        bounds[:carrier_high][carrier] = cost if cost > bounds[:carrier_high][carrier]

        metal = plan.metal_level
        bounds[:metal_low_plan][metal] = plan.id if cost < bounds[:metal_low][metal]
        bounds[:metal_high_plan][metal] = plan.id if cost > bounds[:metal_high][metal]
        bounds[:metal_low][metal] = cost if cost < bounds[:metal_low][metal]
        bounds[:metal_high][metal] = cost if cost > bounds[:metal_high][metal]
      }
      bounds
    end

    def buy_up employer_cost, metal_level, bounds
      return 'No buy up level' if metal_level == 'platinum'
      move_up = {'bronze'=> 'silver', 'silver'=> 'gold', 'gold' => 'platinum'}
      up_metal = move_up[metal_level]
      low = bounds[:metal_low][up_metal] - employer_cost
      high = bounds[:metal_high][up_metal] - employer_cost
      low_dollar = low < 0 ? "-$#{-low.ceil}" : "$#{low.ceil}"
      buy_up = "Buy #{up_metal.capitalize} for #{low_dollar} to $#{high.ceil}"
      puts buy_up
      buy_up
    end
  end
end
