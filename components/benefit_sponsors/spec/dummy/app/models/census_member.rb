class CensusMember
  include Mongoid::Document
  include Mongoid::Timestamps

  field :first_name, type: String
  field :middle_name, type: String
  field :last_name, type: String
  field :name_sfx, type: String

  field :encrypted_ssn, type: String
  field :gender, type: String
  field :dob, type: Date

  field :employee_relationship, type: String
  field :employer_assigned_family_id, type: String

  embeds_one :address
  accepts_nested_attributes_for :address, reject_if: :all_blank, allow_destroy: true

  embeds_one :email
  accepts_nested_attributes_for :email, allow_destroy: true

  def ssn=(new_ssn)
    if !new_ssn.blank?
      write_attribute(:encrypted_ssn, self.class.encrypt_ssn(new_ssn))
    else
      unset_sparse("encrypted_ssn")
    end
  end

  def ssn
    ssn_val = read_attribute(:encrypted_ssn)
    if !ssn_val.blank?
      self.class.decrypt_ssn(ssn_val)
    else
      nil
    end
  end

  def full_name
    [first_name, middle_name, last_name, name_sfx].compact.join(" ")
  end


  class << self 
    
    def encrypt_ssn(val)
      if val.blank?
        return nil
      end
      ssn_val = val.to_s.gsub(/\D/, '')
      SymmetricEncryption.encrypt(ssn_val)
    end

    def decrypt_ssn(val)
      SymmetricEncryption.decrypt(val)
    end

    def find_by_ssn(ssn)
      self.where(encrypted_ssn: encrypt_ssn(ssn)).first
    end
  end
end
