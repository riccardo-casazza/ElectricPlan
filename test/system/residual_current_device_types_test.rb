require "application_system_test_case"

class ResidualCurrentDeviceTypesTest < ApplicationSystemTestCase
  setup do
    @residual_current_device_type = residual_current_device_types(:one)
  end

  test "visiting the index" do
    visit residual_current_device_types_url
    assert_selector "h1", text: "Residual current device types"
  end

  test "should create residual current device type" do
    visit residual_current_device_types_url
    click_on "New residual current device type"

    fill_in "Name", with: @residual_current_device_type.name
    click_on "Create Residual current device type"

    assert_text "Residual current device type was successfully created"
    click_on "Back"
  end

  test "should update Residual current device type" do
    visit residual_current_device_type_url(@residual_current_device_type)
    click_on "Edit this residual current device type", match: :first

    fill_in "Name", with: @residual_current_device_type.name
    click_on "Update Residual current device type"

    assert_text "Residual current device type was successfully updated"
    click_on "Back"
  end

  test "should destroy Residual current device type" do
    visit residual_current_device_type_url(@residual_current_device_type)
    click_on "Destroy this residual current device type", match: :first

    assert_text "Residual current device type was successfully destroyed"
  end
end
