module Validations
  module EmployeeInfo
    def self.included(base)
      base.class_eval do
        include ActiveModel::Validations
        validate :check_dob_by_ability
        validate :check_ssn_by_ability

        def self.define_check_function(name)
          f_name = "check_#{name}_by_ability"
          define_method(f_name) {
            current_user = User.current_user
            return if !self.send("#{name}_changed?") || new_record? || current_user.has_hbx_staff_role?

            if current_user.has_employer_staff_role?
              if is_linked?
                errors.add(name.to_sym, 'does not have the ability to be change after linking')
              end
            else
              errors.add(name.to_sym, 'dose not have the ability to change')
            end
          }
        end

        define_check_function :dob
        define_check_function :ssn

        #def check_dob_by_ability
          #current_user = User.current_user
          #return if !dob_changed? or new_record? or current_user.has_hbx_staff_role?

          #if current_user.has_employer_staff_role?
            #if is_linkable?
              #errors.add(:dob, 'has not ability to change dob after linkable')
            #end
          #else
            #errors.add(:dob, 'has not ability to change dob')
          #end
        #end

        #def check_ssn_by_ability
          #current_user = User.current_user
          #return if !ssn_changed? or new_record? or current_user.has_hbx_staff_role?

          #if current_user.has_employer_staff_role?
            #if is_linkable?
              #errors.add(:ssn, 'has not ability to change ssn after linkable')
            #end
          #else
            #errors.add(:ssn, 'has not ability to change ssn')
          #end
        #end
      end
    end
  end
end
