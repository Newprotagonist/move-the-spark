namespace :demo do
  DEMO_EMAIL = "demo@movethespark.app"

  desc "Crée (ou recrée avec un nouveau mot de passe) le compte démo public affiché sur le portfolio."
  task create: :environment do
    User.find_by(email_address: DEMO_EMAIL)&.destroy!

    password = SecureRandom.alphanumeric(16)
    user = User.create!(email_address: DEMO_EMAIL, password: password, demo: true)
    user.reset_demo_content!

    puts "Compte démo créé : #{user.email_address}"
    puts "Mot de passe (à coller sur le portfolio, non enregistré ailleurs) : #{password}"
  end

  desc "Remet le(s) compte(s) démo à un état propre sans toucher au mot de passe (tourne aussi chaque nuit, voir config/recurring.yml)."
  task reset: :environment do
    DemoResetJob.perform_now
    puts "Compte(s) démo réinitialisé(s)."
  end
end
