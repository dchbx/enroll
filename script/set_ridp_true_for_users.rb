# we still need this commented out code.

def curam_user?(family)
  family.e_case_id.present? && !(family.e_case_id.include? "curam_landing") if family.present?
end

# def user_having_enrollments?(person)
#   if person.primary_family.present? && person.primary_family.active_household.present?
#     person.primary_family.active_household.hbx_enrollments.where(kind: 'individual').present?
#   end
# end

# def consumer_role_boomarked?(person)
#   person.consumer_role.bookmark_url == "/families/home"
# end


# Person.all_consumer_roles.each do |person|
#   begin
#     if person.user && !person.user.identity_verified? && person.primary_family.present?
#       if curam_user?(person) || user_prior_to_enroll?(person) || consumer_role_boomarked?(person)
#         person.user.update_attributes(:identity_final_decision_code => USER::INTERACTIVE_IDENTITY_VERIFICATION_SUCCESS_CODE)
#       end
#     end
#   rescue
#     puts "Bad person record #{person.id}"
#   end
# end

# Addressing records imported from curam on 10/11/2015

# start_date = Date.new(2015,10,10)
start_date = Date.new(2015,10,11)
count = 0
Person.all_consumer_roles.where(:"created_at" => { "$gt" => start_date }, :user => {:$exists => true}).each do |person|
  begin
    if !person.user.identity_verified?
      if curam_user?(person.primary_family)
        person.user.ridp_by_payload!
        puts "updated RIDP status for person FirstName: #{person.first_name} LastName: #{person.last_name} Hbx_Id: #{person.hbx_id}"
        count +=1
      end
    end
  rescue
    puts "Bad person record #{person.id}"
  end
end
puts "Total effected users that were created on 10/11/2015 are #{count}"

