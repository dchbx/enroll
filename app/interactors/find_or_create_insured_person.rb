class FindOrCreateInsuredPerson
  include Interactor

  def call
    user = context.user
    people = Person.match_by_id_info(ssn: context.ssn, dob: context.dob, last_name: context.last_name, first_name: context.first_name)
    person, is_new = nil, nil
    case people.count
    when 1
      person = people.first
      user.save if user
      person.user = user if user
      if person.ssn.nil?
        #matched on last_name and dob
        person.ssn = context.ssn
        person.gender = context.gender
      end
      person.save
      user = person.user if context.role_type == User::ROLES[:consumer]
      person, is_new = person, false
    when 0
      if user.try(:person).try(:present?)
        if user.person.first_name.downcase == context.first_name.downcase and
          user.person.last_name.downcase == context.last_name.downcase # if user enters lowercase during matching.
          person = user.person
          person.update(name_sfx: context.name_sfx,
                        middle_name: context.middle_name,
                        name_pfx: context.name_pfx,
                        ssn: context.ssn,
                        dob: context.dob,
                        gender: context.gender)
          is_new = false
        else
          context.person = nil
          context.is_new = nil
          return
        end
      else
        person, is_new = Person.create(
          user: user,
          name_pfx: context.name_pfx,
          first_name: context.first_name,
          middle_name: context.middle_name,
          last_name: context.last_name,
          name_sfx: context.name_sfx,
          ssn: context.ssn,
          no_ssn: context.no_ssn,
          dob: context.dob,
          gender: context.gender,
        ), true
      end
    else
      # what am I doing here?  More than one person had the same SSN?
      context.person = nil
      context.is_new = nil
      return
    end
    if user.present?
      user.roles << context.role_type unless user.roles.include?(context.role_type)
      user.save
      unless person.emails.count > 0
        if user.email.present?
          person.emails.build(kind: "home", address: user.email)
          person.save
        end
      end
    end
    context.person = person
    context.is_new = is_new
  end
end
