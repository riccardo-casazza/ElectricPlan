require "test_helper"

class ResidualCurrentDevicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @residual_current_device = residual_current_devices(:one)
  end

  test "should get index" do
    get residual_current_devices_url
    assert_response :success
  end

  test "should get new" do
    get new_residual_current_device_url
    assert_response :success
  end

  test "should create residual_current_device" do
    assert_difference("ResidualCurrentDevice.count") do
      post residual_current_devices_url, params: { residual_current_device: { electrical_panel_id: @residual_current_device.electrical_panel_id, max_current: @residual_current_device.max_current, position: @residual_current_device.position, residual_current_device_type_id: @residual_current_device.residual_current_device_type_id, row_number: @residual_current_device.row_number } }
    end

    assert_redirected_to residual_current_device_url(ResidualCurrentDevice.last)
  end

  test "should show residual_current_device" do
    get residual_current_device_url(@residual_current_device)
    assert_response :success
  end

  test "should get edit" do
    get edit_residual_current_device_url(@residual_current_device)
    assert_response :success
  end

  test "should update residual_current_device" do
    patch residual_current_device_url(@residual_current_device), params: { residual_current_device: { electrical_panel_id: @residual_current_device.electrical_panel_id, max_current: @residual_current_device.max_current, position: @residual_current_device.position, residual_current_device_type_id: @residual_current_device.residual_current_device_type_id, row_number: @residual_current_device.row_number } }
    assert_redirected_to residual_current_device_url(@residual_current_device)
  end

  test "should destroy residual_current_device" do
    assert_difference("ResidualCurrentDevice.count", -1) do
      delete residual_current_device_url(@residual_current_device)
    end

    assert_redirected_to residual_current_devices_url
  end
end
