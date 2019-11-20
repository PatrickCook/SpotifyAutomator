desc "This task is called by the Heroku scheduler add-on"
task :import_recently_played => :environment do
  puts "Updating played tracks history"
  BatchImportRecentlyPlayedWorker.perform_async
  puts "done."
end