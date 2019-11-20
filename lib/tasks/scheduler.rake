desc "This task is called by the Heroku scheduler add-on"
task :update_feed => :environment do
  puts "Updating played tracks history"

  puts "done."
end