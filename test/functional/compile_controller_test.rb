require 'test_helper'

class CompileControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

end
