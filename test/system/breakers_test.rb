require "application_system_test_case"

class BreakersTest < ApplicationSystemTestCase
  setup do
    @breaker = breakers(:one)
  end

  test "visiting the index" do
    visit breakers_url
    assert_selector "h1", text: "Breakers"
  end

  test "should create breaker" do
    visit breakers_url
    click_on "New breaker"

    fill_in "Description", with: @breaker.description
    fill_in "Max current", with: @breaker.max_current
    fill_in "Name", with: @breaker.name
    fill_in "Position", with: @breaker.position
    fill_in "Residual current device", with: @breaker.residual_current_device_id
    click_on "Create Breaker"

    assert_text "Breaker was successfully created"
    click_on "Back"
  end

  test "should update Breaker" do
    visit breaker_url(@breaker)
    click_on "Edit this breaker", match: :first

    fill_in "Description", with: @breaker.description
    fill_in "Max current", with: @breaker.max_current
    fill_in "Name", with: @breaker.name
    fill_in "Position", with: @breaker.position
    fill_in "Residual current device", with: @breaker.residual_current_device_id
    click_on "Update Breaker"

    assert_text "Breaker was successfully updated"
    click_on "Back"
  end

  test "should destroy Breaker" do
    visit breaker_url(@breaker)
    click_on "Destroy this breaker", match: :first

    assert_text "Breaker was successfully destroyed"
  end
end
