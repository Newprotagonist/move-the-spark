class SettingsController < ApplicationController
  def edit
    @setting = Setting.instance
  end

  def update
    @setting = Setting.instance
    if @setting.update(setting_params)
      redirect_to edit_settings_path, notice: "Réglages mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def setting_params
    params.require(:setting).permit(:points_per_goal, :default_appointment_lead_minutes, :daily_goal_reminder_time)
  end
end
