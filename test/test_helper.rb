ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"
require "minitest/mock"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

# Every controller/request test signs in as a default user unless it says
# otherwise — the app was single-user until now, so this keeps that the
# default in tests too; tests that specifically need two users sign in a
# second one (users(:two)) explicitly instead of relying on this default.
class ActionDispatch::IntegrationTest
  setup do
    @current_user = users(:one)
    sign_in_as(@current_user)
  end
end
