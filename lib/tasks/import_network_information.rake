namespace :import do
  desc "importing network information"
  task :network_information => [:environment] do

    network_hash = {
      "88806MA0020003" => "This plan is provided on the \"Direct Care\" network, a Limited Provider Network. A \"Limited Provider Network\" means that its network of providers (such as doctors and hospitals) is smaller than the carrier’s general provider network. Before enrolling in this Limited Network plan, please read this information at www.mahealthconnector.org/limited to help you decide if a Limited Network plan is right for you.",
      "88806MA0020006" => "This plan is provided on the \"Direct Care\" network, a Limited Provider Network. A \"Limited Provider Network\" means that its network of providers (such as doctors and hospitals) is smaller than the carrier’s general provider network. Before enrolling in this Limited Network plan, please read this information at www.mahealthconnector.org/limited to help you decide if a Limited Network plan is right for you.",
      "88806MA0020045" => "This plan is provided on the \"Direct Care\" network, a Limited Provider Network. A \"Limited Provider Network\" means that its network of providers (such as doctors and hospitals) is smaller than the carrier’s general provider network. Before enrolling in this Limited Network plan, please read this information at www.mahealthconnector.org/limited to help you decide if a Limited Network plan is right for you.",
      "88806MA0020008" => "This plan is provided on the \"Direct Care\" network, a Limited Provider Network. A \"Limited Provider Network\" means that its network of providers (such as doctors and hospitals) is smaller than the carrier’s general provider network. Before enrolling in this Limited Network plan, please read this information at www.mahealthconnector.org/limited to help you decide if a Limited Network plan is right for you.",
      "88806MA0100002" => "This plan is provided on the \"Community Care\" network, a Limited Provider Network. A \"Limited Provider Network\" means that its network of providers (such as doctors and hospitals) is smaller than the carrier’s general provider network. Before enrolling in this Limited Network plan, please read this information at www.mahealthconnector.org/limited to help you decide if a Limited Network plan is right for you.",
      "88806MA0020052" => "This plan is provided on the \"Direct Care\" network, a Limited Provider Network. A \"Limited Provider Network\" means that its network of providers (such as doctors and hospitals) is smaller than the carrier’s general provider network. Before enrolling in this Limited Network plan, please read this information at www.mahealthconnector.org/limited to help you decide if a Limited Network plan is right for you."
    }

    network_hash.each do |hios_base_id, network_information|
      plan = Plan.where(active_year: 2017, hios_base_id: hios_base_id).first
      if plan.present?
        plan.update_attributes(network_information: network_information)
        puts "Successfully updated network information for #{plan.active_year} plan with hios_id: #{plan.hios_id}"
      end
    end
  end
end
