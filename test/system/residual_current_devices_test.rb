require "application_system_test_case"

class ResidualCurrentDevicesTest < ApplicationSystemTestCase
  setup do
    @residual_current_device = residual_current_devices(:one)
  end

  test "visiting the index" do
    visit residual_current_devices_url
    assert_selector "h1", text: "Residual current devices"
  end

  test "should create residual current device" do
    visit residual_current_devices_url
    click_on "New residual current device"

    fill_in "Electrical panel", with: @residual_current_device.electrical_panel_id
    fill_in "Max current", with: @residual_current_device.max_current
    fill_in "Position", with: @residual_current_device.position
    fill_in "Residual current device type", with: @residual_current_device.residual_current_device_type_id
    fill_in "Row number", with: @residual_current_device.row_number
    click_on "Create Residual current device"

    assert_text "Residual current device was successfully created"
    click_on "Back"
  end

  test "should update Residual current device" do
    visit residual_current_device_url(@residual_current_device)
    click_on "Edit this residual current device", match: :first

    fill_in "Electrical panel", with: @residual_current_device.electrical_panel_id
    fill_in "Max current", with: @residual_current_device.max_current
    fill_in "Position", with: @residual_current_device.position
    fill_in "Residual current device type", with: @residual_current_device.residual_current_device_type_id
    fill_in "Row number", with: @residual_current_device.row_number
    click_on "Update Residual current device"

    assert_text "Residual current device was successfully updated"
    click_on "Back"
  end

  test "should destroy Residual current device" do
    visit residual_current_device_url(@residual_current_device)
    click_on "Destroy this residual current device", match: :first

    assert_text "Residual current device was successfully destroyed"
  end
end
