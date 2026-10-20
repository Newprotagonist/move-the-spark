namespace :users do
  desc "Create an account for someone you're inviting (no self-service signup). Prints a one-time password — pass it along out-of-band (text, in person); it is not stored or sent anywhere."
  task :invite, [ :email_address ] => :environment do |_t, args|
    email_address = args.email_address.presence || abort("Usage: bin/rails \"users:invite[someone@example.com]\"")

    password = SecureRandom.alphanumeric(16)
    user = User.create!(email_address: email_address, password: password)

    puts "Compte créé pour #{user.email_address}."
    puts "Mot de passe (à transmettre, non enregistré ailleurs) : #{password}"
  end

  desc "Print a password-reset link for a user who forgot their password, valid 15 minutes. No email is sent — share the link out-of-band."
  task :reset_password_link, [ :email_address ] => :environment do |_t, args|
    email_address = args.email_address.presence || abort("Usage: bin/rails \"users:reset_password_link[someone@example.com]\"")

    user = User.find_by(email_address: email_address) || abort("Aucun compte pour #{email_address}.")
    abort "#{email_address} est le compte démo public : voir demo:create pour en changer le mot de passe." if user.demo?
    host = ENV["RESET_LINK_HOST"].presence || (Rails.env.production? ? "https://movethespark.com" : "http://localhost:3000")

    puts "#{host}/passwords/#{user.password_reset_token}/edit"
  end
end
