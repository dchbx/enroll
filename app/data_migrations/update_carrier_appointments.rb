require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateCarrierAppointments < MongoidMigrationTask
  def migrate

    mappings = {
            "aetna_health_inc" => "Aetna Health Inc" ,
            "aetna_life_insurance_company" => "Aetna Life Insurance Company", 
            "carefirst_bluechoice_inc" => "Carefirst Bluechoice Inc",
            "group_hospitalization_and_medical_services_inc" => "Group Hospitalization and Medical Services Inc",
            "kaiser_foundation" => "Kaiser Foundation",
            "optimum_choice" => "Optimum Choice",
            "united_health_care_insurance" => "United Health Care Insurance", 
            "united_health_care_mid_atlantic" => "United Health Care Mid Atlantic"
            }
    BrokerRole.all.each do |br|
      if br.carrier_appointments.all?{|key, value| key.include?('_') }
          br.carrier_appointments = br.carrier_appointments.map {|k, v| [mappings[k], v] }.to_h
          br.save
      elsif br.carrier_appointments.all?{|key, value| !key.include?('_') }
        #Do NOTHING
      else
        all_carrier_appointment = BrokerRole::BROKER_CARRIER_APPOINTMENTS.stringify_keys
        data = br.carrier_appointments.map {|k, v| mappings[k] ? [mappings[k], v] : nil}.compact.to_h
        br.carrier_appointments = all_carrier_appointment.merge! data
        br.save
      end
    end
  end
end
