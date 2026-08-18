class AddStreakBonusCapToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :streak_bonus_cap, :integer, default: 10, null: false
  end
end
