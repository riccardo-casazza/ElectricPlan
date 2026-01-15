require "application_system_test_case"

class DwellingsTest < ApplicationSystemTestCase
  setup do
    @dwelling = dwellings(:one)
  end

  test "visiting the index" do
    visit dwellings_url
    assert_selector "h1", text: "Dwellings"
  end

  test "should create dwelling" do
    visit dwellings_url
    click_on "New dwelling"

    fill_in "Name", with: @dwelling.name
    click_on "Create Dwelling"

    assert_text "Dwelling was successfully created"
    click_on "Back"
  end

  test "should update Dwelling" do
    visit dwelling_url(@dwelling)
    click_on "Edit this dwelling", match: :first

    fill_in "Name", with: @dwelling.name
    click_on "Update Dwelling"

    assert_text "Dwelling was successfully updated"
    click_on "Back"
  end

  test "should destroy Dwelling" do
    visit dwelling_url(@dwelling)
    click_on "Destroy this dwelling", match: :first

    assert_text "Dwelling was successfully destroyed"
  end
end
