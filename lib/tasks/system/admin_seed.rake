namespace :system do
  desc "Load Roles, permissions"
  task :admin_seed => :environment do

    puts "::: Creating Admin Roles ::::"
    
    Rake::Task['permissions:assign_current_permissions'].invoke

    super_admin = FactoryBot.create(:user, :with_person, oim_id: 'admin@dc.gov', password: 'aA1!aA1!aA1!', password_confirmation: 'aA1!aA1!aA1!')
    hbx_read_only = FactoryBot.create(:user, :with_person)
    hbx_csr_supervisor = FactoryBot.create(:user, :with_person)
    hbx_csr_tier1 = FactoryBot.create(:user, :with_person)
    hbx_csr_tier2 = FactoryBot.create(:user, :with_person)
    developer = FactoryBot.create(:user, :with_person)
    hbx_tier3 = FactoryBot.create(:user, :with_person)
    hbx_staff = FactoryBot.create(:user, :with_person)

    hbx_profile_id = FactoryBot.create(:hbx_profile).id
    HbxStaffRole.create!(person: hbx_staff.person, permission_id: Permission.hbx_staff.id, subrole: 'hbx_staff', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!(person: hbx_read_only.person, permission_id: Permission.hbx_read_only.id, subrole: 'hbx_read_only', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!(person: hbx_csr_supervisor.person, permission_id: Permission.hbx_csr_supervisor.id, subrole: 'hbx_csr_supervisor', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!(person: hbx_csr_tier1.person, permission_id: Permission.hbx_csr_tier1.id, subrole: 'hbx_csr_tier1', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!(person: hbx_csr_tier2.person, permission_id: Permission.hbx_csr_tier2.id, subrole: 'hbx_csr_tier2', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!(person: developer.person, permission_id: Permission.developer.id, subrole: 'developer', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!(person: hbx_tier3.person, permission_id: Permission.hbx_tier3.id, subrole: 'hbx_tier3', hbx_profile_id: hbx_profile_id)
    HbxStaffRole.create!(person: super_admin.person, permission_id: Permission.super_admin.id, subrole: 'super_admin', hbx_profile_id: hbx_profile_id)

    puts "::: Created Admin Roles. ::::"
    puts "::: Admin Credentials ::::"
    puts "username - admin@dc.gov"
    puts 'password - aA1!aA1!aA1!'
  end
end
