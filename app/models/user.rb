class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :goals, dependent: :destroy
  has_many :goal_completions, through: :goals
  has_many :appointments, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy
  has_one :setting, dependent: :destroy

  scope :not_demo, -> { where(demo: false) }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  after_create :create_setting!

  # Identifiants publics sur le portfolio : un visiteur peut librement
  # modifier/supprimer les objectifs et rendez-vous du compte démo, mais
  # jamais son mot de passe ni le compte lui-même — voir passwords_controller
  # et users.rake. Cette méthode efface les objectifs/rendez-vous existants
  # et recrée le même jeu de démonstration, sans jamais toucher au mot de
  # passe. Appelée chaque nuit par Solid Queue (config/recurring.yml).
  def reset_demo_content!
    raise "reset_demo_content! appelé sur un compte non-démo" unless demo?

    goals.destroy_all
    appointments.destroy_all
    push_subscriptions.destroy_all

    lire = goals.create!(title: "Lire 20 minutes", recurring: true, frequency: "daily", active_from: 9.days.ago.to_date)
    sport = goals.create!(title: "Sport", recurring: true, frequency: "daily", active_from: 9.days.ago.to_date)
    mediter = goals.create!(title: "Méditer", recurring: true, frequency: "daily", active_from: 9.days.ago.to_date)
    courses = goals.create!(title: "Faire les courses", recurring: true, frequency: "weekly", active_from: 9.days.ago.to_date)

    points = setting.points_per_goal
    5.downto(1) do |n|
      day = n.days.ago.to_date
      [ lire, sport, mediter ].each do |g|
        g.goal_completions.create!(occurred_on: day, completed_at: day.to_time + rand(18..21).hours, points_awarded: points)
      end
    end
    lire.goal_completions.create!(occurred_on: Date.current, completed_at: Time.current, points_awarded: points)
    courses.goal_completions.create!(occurred_on: 1.week.ago.to_date.beginning_of_week, completed_at: 3.days.ago, points_awarded: points)

    appointments.create!(title: "Dentiste", starts_at: 1.day.from_now.change(hour: 10, min: 30))
  end
end
