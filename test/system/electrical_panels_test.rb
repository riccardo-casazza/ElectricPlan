require "application_system_test_case"

class ElectricalPanelsTest < ApplicationSystemTestCase
  setup do
    @electrical_panel = electrical_panels(:one)
  end

  test "visiting the index" do
    visit electrical_panels_url
    assert_selector "h1", text: "Electrical panels"
  end

  test "should create electrical panel" do
    visit electrical_panels_url
    click_on "New electrical panel"

    fill_in "Name", with: @electrical_panel.name
    fill_in "Room", with: @electrical_panel.room_id
    click_on "Create Electrical panel"

    assert_text "Electrical panel was successfully created"
    click_on "Back"
  end

  test "should update Electrical panel" do
    visit electrical_panel_url(@electrical_panel)
    click_on "Edit this electrical panel", match: :first

    fill_in "Name", with: @electrical_panel.name
    fill_in "Room", with: @electrical_panel.room_id
    click_on "Update Electrical panel"

    assert_text "Electrical panel was successfully updated"
    click_on "Back"
  end

  test "should destroy Electrical panel" do
    visit electrical_panel_url(@electrical_panel)
    click_on "Destroy this electrical panel", match: :first

    assert_text "Electrical panel was successfully destroyed"
  end
end
