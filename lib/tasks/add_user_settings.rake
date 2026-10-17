desc "add user_settings to all users"

task :add_user_settings => :environment do
  User.all.each do |user|
    if user.user_settings.nil?
      default = UserSettings.new(dark_mode: false)
      default.save!
      user.user_settings = default
      user.save!
    end
  end
end
