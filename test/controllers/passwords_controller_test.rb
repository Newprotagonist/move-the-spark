require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_out
    @user = users(:one)
  end

  test "edit renders the reset form for a valid token" do
    get edit_password_path(@user.password_reset_token)
    assert_response :success
  end

  test "edit redirects to login for an invalid or expired token" do
    get edit_password_path("not-a-real-token")
    assert_redirected_to new_session_path
  end

  test "update sets the new password and signs out every existing session" do
    @user.sessions.create!
    assert_not_empty @user.sessions

    patch password_path(@user.password_reset_token),
      params: { password: "new-password", password_confirmation: "new-password" }

    assert_redirected_to new_session_path
    assert @user.reload.authenticate("new-password")
    assert_empty @user.sessions
  end

  test "update re-renders when the confirmation does not match" do
    token = @user.password_reset_token

    patch password_path(token), params: { password: "new-password", password_confirmation: "does-not-match" }

    assert_redirected_to edit_password_path(token)
  end

  test "update refuse de changer le mot de passe du compte démo, même avec un token valide" do
    demo = User.create!(email_address: "demo@movethespark.app", password: "password", demo: true)

    patch password_path(demo.password_reset_token),
      params: { password: "new-password", password_confirmation: "new-password" }

    assert_redirected_to new_session_path
    assert demo.reload.authenticate("password")
  end
end
