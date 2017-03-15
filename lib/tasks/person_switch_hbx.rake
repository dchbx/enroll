namespace :person do
  desc "switch hbx from person 2 to person 1" do
    task :switch_hbx => :environment do
      #Correct Person
      p1  = Person.where(hbx_id:19767831).first
      #Person to Move
      p2 = Person.where(hbx_id:19899836).first
      
      #Update p1 hbx to move p2 hbx id to it
      p1.update(hbx_id:19767832)
      #update p2 hbx_id to 19767831
      p2.update(hbx_id:19767831)
    end
  end
end