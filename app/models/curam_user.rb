class CuramUser
  include Mongoid::Document

  field :username, type: String
  field :email, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :encrypted_ssn, type: String
  field :dob, type: Date

  index({email: 1})
  index({username: 1})
  index({encrypted_ssn: 1, dob: 1})
  index({last_name: 1, first_name: 1, dob: 1})

  def self.match_email(value)
    where(email: /^#{value}$/i)
  end

  def self.match_username(value)
    where(username: /^#{value}$/i)
  end

  def self.match_unique_login(value)
    self.match_email(value).to_a + self.match_username(value).to_a
  end

  def self.encrypt_ssn(val)
    if val.blank?
      return nil
    end
    ssn_val = val.to_s.gsub(/\D/, '')
    SymmetricEncryption.encrypt(ssn_val)
  end

  def self.decrypt_ssn(val)
    SymmetricEncryption.decrypt(val)
  end

  def self.match_ssn ssn
    CuramUser.where(encrypted_ssn: self.encrypt_ssn(ssn)).exists?
  end

  def self.match_ssn_dob(ssn, dob)
    CuramUser.where(encrypted_ssn: self.encrypt_ssn(ssn), dob: dob)
  end

  def self.match_fname_lname_dob(fname, lname, dob)
    f_name_regex = Regexp.compile(Regexp.escape(fname.to_s), true)
    l_name_regex = Regexp.compile(Regexp.escape(lname.to_s), true)
    self.where(first_name: f_name_regex, last_name: l_name_regex, dob: dob)
  end

  def self.search_for(fname, lname, ssn, dob)
    if ssn.blank?
      self.match_fname_lname_dob(fname, lname, dob)
    else
      self.match_ssn_dob(ssn, dob)
    end
  end

  def ssn=(new_ssn)
    write_attribute(:encrypted_ssn, CuramUser.encrypt_ssn(new_ssn))
  end

  def ssn
    ssn_val = read_attribute(:encrypted_ssn)
    if !ssn_val.blank?
      CuramUser.decrypt_ssn(ssn_val)
    else
      nil
    end
  end

  def self.name_in_curam_list(fname, lname)
    self.where(first_name: fname, last_name: lname).any? ? true : false
  end

end
