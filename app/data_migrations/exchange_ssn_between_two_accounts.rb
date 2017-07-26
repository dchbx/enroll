require File.join(Rails.root, "lib/mongoid_migration_task")
class ExchangeSsnBetweenTwoAccounts< MongoidMigrationTask
  def migrate
    hbx_id_1=ENV['hbx_id_1']
    hbx_id_2=ENV['hbx_id_2']
    person1 = Person.where(hbx_id:hbx_id_1).first
    person2 = Person.where(hbx_id:hbx_id_2).first
    if person1.nil?
      puts "No person found with hbx_id #{hbx_id_1}" unless Rails.env.test?
    elsif person2.nil?
      puts "No person found with hbx_id #{hbx_id_2}" unless Rails.env.test?
    else
      ssn1=person1.ssn
      ssn2=person2.ssn
      if ssn1.nil?
        puts "person with hbx_id  #{hbx_id_1} has no ssn" unless Rails.env.test?
      elsif ssn2.nil?
        puts "person with hbx_id  #{hbx_id_2} has no ssn" unless Rails.env.test?
      else
        person1.unset(:encrypted_ssn)
        person2.unset(:encrypted_ssn)
        person1.update_attributes(ssn: ssn2)
        person2.update_attributes(ssn: ssn1)
      end
    end
  end
end
