require "test_helper"

class FloorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @floor = floors(:one)
  end

  test "should get index" do
    get floors_url
    assert_response :success
  end

  test "should get new" do
    get new_floor_url
    assert_response :success
  end

  test "should create floor" do
    assert_difference("Floor.count") do
      post floors_url, params: { floor: { name: @floor.name } }
    end

    assert_redirected_to floor_url(Floor.last)
  end

  test "should show floor" do
    get floor_url(@floor)
    assert_response :success
  end

  test "should get edit" do
    get edit_floor_url(@floor)
    assert_response :success
  end

  test "should update floor" do
    patch floor_url(@floor), params: { floor: { name: @floor.name } }
    assert_redirected_to floor_url(@floor)
  end

  test "should destroy floor" do
    assert_difference("Floor.count", -1) do
      delete floor_url(@floor)
    end

    assert_redirected_to floors_url
  end
end
