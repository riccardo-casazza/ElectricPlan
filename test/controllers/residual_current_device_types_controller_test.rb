require "test_helper"

class ResidualCurrentDeviceTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @residual_current_device_type = residual_current_device_types(:one)
  end

  test "should get index" do
    get residual_current_device_types_url
    assert_response :success
  end

  test "should get new" do
    get new_residual_current_device_type_url
    assert_response :success
  end

  test "should create residual_current_device_type" do
    assert_difference("ResidualCurrentDeviceType.count") do
      post residual_current_device_types_url, params: { residual_current_device_type: { name: @residual_current_device_type.name } }
    end

    assert_redirected_to residual_current_device_type_url(ResidualCurrentDeviceType.last)
  end

  test "should show residual_current_device_type" do
    get residual_current_device_type_url(@residual_current_device_type)
    assert_response :success
  end

  test "should get edit" do
    get edit_residual_current_device_type_url(@residual_current_device_type)
    assert_response :success
  end

  test "should update residual_current_device_type" do
    patch residual_current_device_type_url(@residual_current_device_type), params: { residual_current_device_type: { name: @residual_current_device_type.name } }
    assert_redirected_to residual_current_device_type_url(@residual_current_device_type)
  end

  test "should destroy residual_current_device_type" do
    assert_difference("ResidualCurrentDeviceType.count", -1) do
      delete residual_current_device_type_url(@residual_current_device_type)
    end

    assert_redirected_to residual_current_device_types_url
  end
end
