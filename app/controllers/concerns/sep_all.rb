module SepAll

  def includeBothMarkets
    dt_query = extract_datatable_parameters
    families_dt = []
    all_families = Family.all
    if dt_query.search_string.blank?
      families_dt = all_families
    else
      person_ids = Person.search(dt_query.search_string).pluck(:id)
      families_dt = all_families.where({
      "family_members.person_id" => {"$in" => person_ids}
      })
    end

    @draw = dt_query.draw
    @state = 'both'
    @total_records = sortData(all_families, @state)
    @records_filtered = sortData(families_dt, @state)
    @dataArray = sortData(families_dt, @state, 'yes')
    @families = @dataArray.slice(dt_query.skip.to_i, dt_query.take.to_i)
  end

  def includeIVL
    if QualifyingLifeEventKind.where(:market_kind => 'individual').present?
      all_families_in_ivl = Family.all
      dt_query = extract_datatable_parameters
      families_dt = []

      if dt_query.search_string.blank?
        families_dt = all_families_in_ivl
      else
        person_ids = Person.search(dt_query.search_string).pluck(:id)
        families_dt = all_families_in_ivl.where({
        "family_members.person_id" => {"$in" => person_ids}
        })
      end

      @draw = dt_query.draw
      @state = 'ivl'
      @total_records = sortData(all_families_in_ivl, @state)
      @records_filtered = sortData(families_dt, @state)
      @dataArray = sortData(families_dt, @state, 'yes')
      @families = @dataArray.slice(dt_query.skip.to_i, dt_query.take.to_i)
    end
  end

  def includeShop
    if QualifyingLifeEventKind.where(:market_kind => 'shop').present?
      all_families_in_shop = Family.all
      dt_query = extract_datatable_parameters
      families_dt = []

      if dt_query.search_string.blank?
        families_dt = all_families_in_shop
      else
        person_ids = Person.search(dt_query.search_string).pluck(:id)
        families_dt = all_families_in_shop.where({
        "family_members.person_id" => {"$in" => person_ids}
        })
      end

      @draw = dt_query.draw
      @state = 'shop'
      @total_records = sortData(all_families_in_shop, @state)
      @records_filtered = sortData(families_dt, @state)
      @dataArray = sortData(families_dt, @state, 'yes')
      @families = @dataArray.slice(dt_query.skip.to_i, dt_query.take.to_i)
    end
  end

  def createSep
    qle = QualifyingLifeEventKind.find(params[:qle_id])
    @family = Family.find(params[:person])
    @name = params.permit(:firstName)[:firstName] + " " + params.permit(:lastName)[:lastName] 
    special_enrollment_period = @family.special_enrollment_periods.new(effective_on_kind: params[:effective_on_kind])
    special_enrollment_period.selected_effective_on = params.permit(:effective_on_date)[:effective_on_date] if params[:effective_on_date].present?
    special_enrollment_period.start_on = Date.strptime(params[:start_on], "%m/%d/%Y") if params[:start_on].present?
    special_enrollment_period.end_on = Date.strptime(params[:end_on], "%m/%d/%Y") if params[:end_on].present?
    special_enrollment_period.qualifying_life_event_kind = qle
    special_enrollment_period.admin_comment = params.permit(:admin_comment)[:admin_comment] if params[:admin_comment].present?
    special_enrollment_period.csl_num = params.permit(:csl_num)[:csl_num] if params[:csl_num].present?
    special_enrollment_period.next_poss_effective_date = Date.strptime(params[:next_poss_effective_date], "%m/%d/%Y") if params[:next_poss_effective_date].present?
    special_enrollment_period.option1_date = Date.strptime(params[:option1_date], "%m/%d/%Y") if params[:option1_date].present?
    special_enrollment_period.option2_date = Date.strptime(params[:option2_date], "%m/%d/%Y") if params[:option2_date].present?
    special_enrollment_period.option3_date = Date.strptime(params[:option3_date], "%m/%d/%Y") if params[:option3_date].present?
    special_enrollment_period.qle_on = Date.strptime(params[:event_date], "%m/%d/%Y") if params[:event_date].present?
    special_enrollment_period.market_kind = params.permit(:market_kind)[:market_kind] if params[:market_kind].present?
  
    if special_enrollment_period.save
      flash[:notice] = 'SEP added for ' + @name
    else
      special_enrollment_period.errors.full_messages.each do |message|
      flash[:error] = "SEP not saved. " + message
      end
    end
  end

  def sortData(families, state, returnData=nil)
    init_arr = []
    if (state == 'both')
      families.each do|f| 
        if f.primary_applicant.person.consumer_role.present? || f.primary_applicant.person.active_employee_roles.present?        
          init_arr.push(f)
        end
      end
    elsif (state == 'ivl')
      families.each do|f|
        if f.primary_applicant.person.consumer_role.present? 
          init_arr.push(f)
        end
      end
    else
      families.each do|f|
        if f.primary_applicant.person.active_employee_roles.present?
          init_arr.push(f)
        end
      end
    end
   returnData == 'yes' ? init_arr : init_arr.length;
  end
end