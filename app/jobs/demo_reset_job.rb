# Remet chaque nuit le(s) compte(s) démo public(s) à un état propre — voir
# User#reset_demo_content! et config/recurring.yml.
class DemoResetJob < ApplicationJob
  queue_as :default

  def perform
    User.where(demo: true).find_each(&:reset_demo_content!)
  end
end
