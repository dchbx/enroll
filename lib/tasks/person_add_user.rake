namespace :person do
  desc "add user to person account"
  task :add_user => :environment do
    user = User.where(email:/emiliefokkelman@gmail.com/).first
    person = Person.where(hbx_id:19906687).first
    person.update(user_id:user.id)
  end
end