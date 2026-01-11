require "test_helper"

class ElectricalPanelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @electrical_panel = electrical_panels(:one)
  end

  test "should get index" do
    get electrical_panels_url
    assert_response :success
  end

  test "should get new" do
    get new_electrical_panel_url
    assert_response :success
  end

  test "should create electrical_panel" do
    assert_difference("ElectricalPanel.count") do
      post electrical_panels_url, params: { electrical_panel: { name: @electrical_panel.name, room_id: @electrical_panel.room_id } }
    end

    assert_redirected_to electrical_panel_url(ElectricalPanel.last)
  end

  test "should show electrical_panel" do
    get electrical_panel_url(@electrical_panel)
    assert_response :success
  end

  test "should get edit" do
    get edit_electrical_panel_url(@electrical_panel)
    assert_response :success
  end

  test "should update electrical_panel" do
    patch electrical_panel_url(@electrical_panel), params: { electrical_panel: { name: @electrical_panel.name, room_id: @electrical_panel.room_id } }
    assert_redirected_to electrical_panel_url(@electrical_panel)
  end

  test "should destroy electrical_panel" do
    assert_difference("ElectricalPanel.count", -1) do
      delete electrical_panel_url(@electrical_panel)
    end

    assert_redirected_to electrical_panels_url
  end
end
