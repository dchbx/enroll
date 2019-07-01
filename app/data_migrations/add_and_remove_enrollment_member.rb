require File.join(Rails.root, "lib/mongoid_migration_task")

class AddAndRemoveEnrollmentMember < MongoidMigrationTask
  def migrate
    @enrollment_input = get_enrollment_input.to_s
    @person_to_remove_input = get_person_to_remove_input.to_s
    @person_to_add_input = get_person_to_add_input.to_s
    @family = get_enrollment_family
    if @family
      @enrollment = HbxEnrollment.where(hbx_id: @enrollment_input).first
      @family_member_id = @family.active_household.family_members.select{|fm| fm.person.hbx_id == @person_to_add_input}.try(:first).try(:id)
      fix_enrollment
    else
      abort("Aborted! Can' find any family with #{@enrollment_input} enrollment ID.") unless Rails.env.test?
    end
  end

  def fix_enrollment
    delete_enrollment_member if (@person_to_remove_input && @person_to_remove_input != 'skip')
    add_enrollment_member if (@person_to_add_input && @person_to_add_input != 'skip' && @family_member_id)
    if @enrollment.save!
      puts "Person with hbx_id: #{@person_to_remove_input} was removed from enrollment hbx_id: #{@enrollment_input}" unless Rails.env.test?
      puts "Person with hbx_id: #{@person_to_add_input} was added to enrollment hbx_id: #{@enrollment_input}" unless Rails.env.test?
    end
  end

  def delete_enrollment_member
    if @enrollment.hbx_enrollment_members.select{|em| em.person.hbx_id==@person_to_remove_input}.try(:first).try(:delete)
      puts "Removed." unless Rails.env.test?
    end
  end

  def add_enrollment_member
    @enrollment.hbx_enrollment_members.push(new_member)
    puts "Added." unless Rails.env.test?
  end

  def new_member
    HbxEnrollmentMember.new({
                                applicant_id: @family_member_id,
                                eligibility_date: @enrollment.subscriber.eligibility_date,
                                coverage_start_on: @enrollment.subscriber.coverage_start_on
                            })
  end

  def get_enrollment_input
    print "Provide Enrollment hbx_id: " unless Rails.env.test?
    check_input(admin_input, "get_enrollment_input")
  end

  def get_person_to_remove_input
    print "Person hbx_id to REMOVE from enrollment or print 'skip': " unless Rails.env.test?
    check_input(admin_input, "get_person_to_remove_input")
  end

  def get_person_to_add_input
    print "Person hbx_id to ADD to enrollment or print 'skip': " unless Rails.env.test?
    check_input(admin_input, "get_person_to_add_input")
  end

  def admin_input
    begin
      input = STDIN.gets.chomp.to_s.strip
      return input if input == 'skip'
      Integer(input)
    rescue
      print "Wrong input! Hbx_id can have only numeric values. Print one more time: " unless Rails.env.test?
      retry
    end
  end

  def check_input(input, caller)
    puts "\nIs this correct input: #{input}? Y/N. 'EXIT' - to interrupt the process." unless Rails.env.test?
    answer = STDIN.gets.chomp.downcase
    case answer
      when ("y" || "yes")
        input
      when ("n" || "no")
        eval(caller)
      when "exit"
        abort("You've interrupted the data fix process.")
    end
  end

  def get_enrollment_family
    HbxEnrollment.where(hbx_id: @enrollment_input).first.family
  end
end
