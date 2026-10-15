class PasswordsController < ApplicationController
  # No "forgot password" email flow — ActionMailer has no SMTP configured in
  # production (see config/environments/production.rb). The owner generates
  # a reset link by hand in the console (user.password_reset_token, via
  # has_secure_password's built-in signed/expiring token) and sends it
  # out-of-band (SMS, in person) instead.
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  before_action { @fullscreen = true }

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: "Mot de passe mis à jour."
    else
      redirect_to edit_password_path(params[:token]), alert: "Les mots de passe ne correspondent pas."
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_session_path, alert: "Ce lien de réinitialisation n'est plus valide."
    end
end
