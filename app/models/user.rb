class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :goals, dependent: :destroy
  has_many :goal_completions, through: :goals
  has_many :appointments, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy
  has_one :setting, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  after_create :create_setting!
end
