class AddUserRefToAppointments < ActiveRecord::Migration[8.1]
  def change
    add_reference :appointments, :user, null: true, foreign_key: true
  end
end
