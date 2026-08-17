class SettingsController < ApplicationController
  before_action -> { @sheet = true }, only: [ :edit, :update ]

  def edit
    @setting = Setting.instance
  end

  def update
    @setting = Setting.instance
    if @setting.update(setting_params)
      # Not back to itself: settings is opened as a sheet from the profile
      # page, and sheet pages don't render flash messages (no <main> there) —
      # redirecting to a real page is also what closes the sheet.
      redirect_to profile_path, notice: "Réglages mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def setting_params
    params.require(:setting).permit(:points_per_goal, :default_appointment_lead_minutes, :daily_goal_reminder_time)
  end
end
