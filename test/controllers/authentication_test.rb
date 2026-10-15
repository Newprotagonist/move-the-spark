require "test_helper"

# Cross-cutting authentication behavior (the Authentication concern, included
# by every controller via ApplicationController) rather than any one
# controller's own logic — see app/controllers/concerns/authentication.rb.
class AuthenticationTest < ActionDispatch::IntegrationTest
  test "an unauthenticated request is redirected to the login page" do
    sign_out

    get root_path

    assert_redirected_to new_session_path
  end

  test "the PWA manifest and healthcheck stay reachable without signing in" do
    sign_out

    get rails_health_check_path
    assert_response :success

    get pwa_manifest_path(format: :json)
    assert_response :success
  end
end
