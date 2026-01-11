require "test_helper"

class BreakersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @breaker = breakers(:one)
  end

  test "should get index" do
    get breakers_url
    assert_response :success
  end

  test "should get new" do
    get new_breaker_url
    assert_response :success
  end

  test "should create breaker" do
    assert_difference("Breaker.count") do
      post breakers_url, params: { breaker: { description: @breaker.description, max_current: @breaker.max_current, name: @breaker.name, position: @breaker.position, residual_current_device_id: @breaker.residual_current_device_id } }
    end

    assert_redirected_to breaker_url(Breaker.last)
  end

  test "should show breaker" do
    get breaker_url(@breaker)
    assert_response :success
  end

  test "should get edit" do
    get edit_breaker_url(@breaker)
    assert_response :success
  end

  test "should update breaker" do
    patch breaker_url(@breaker), params: { breaker: { description: @breaker.description, max_current: @breaker.max_current, name: @breaker.name, position: @breaker.position, residual_current_device_id: @breaker.residual_current_device_id } }
    assert_redirected_to breaker_url(@breaker)
  end

  test "should destroy breaker" do
    assert_difference("Breaker.count", -1) do
      delete breaker_url(@breaker)
    end

    assert_redirected_to breakers_url
  end
end
