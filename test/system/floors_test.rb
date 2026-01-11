require "application_system_test_case"

class FloorsTest < ApplicationSystemTestCase
  setup do
    @floor = floors(:one)
  end

  test "visiting the index" do
    visit floors_url
    assert_selector "h1", text: "Floors"
  end

  test "should create floor" do
    visit floors_url
    click_on "New floor"

    fill_in "Name", with: @floor.name
    click_on "Create Floor"

    assert_text "Floor was successfully created"
    click_on "Back"
  end

  test "should update Floor" do
    visit floor_url(@floor)
    click_on "Edit this floor", match: :first

    fill_in "Name", with: @floor.name
    click_on "Update Floor"

    assert_text "Floor was successfully updated"
    click_on "Back"
  end

  test "should destroy Floor" do
    visit floor_url(@floor)
    click_on "Destroy this floor", match: :first

    assert_text "Floor was successfully destroyed"
  end
end
