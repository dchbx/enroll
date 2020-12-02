require 'csv'

timestamp = Time.now.strftime('%Y%m%d%H%M')

def fields_for_record
  Permission.attribute_names.reject{|n| ["_id", "updated_at", "updated_by_id", "created_at"].include? n}
end

CSV.open("ea_user_roles_permissions_#{timestamp}.csv","w") do |csv|
  csv << fields_for_record
  Permission.all.each do |perm|
    permissions = []
    fields_for_record.each do |f|
      permissions << perm.send(f)
    end
    csv << permissions
  end
end