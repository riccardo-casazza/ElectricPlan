require "test_helper"

class DwellingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @dwelling = dwellings(:one)
  end

  test "should get index" do
    get dwellings_url
    assert_response :success
  end

  test "should get new" do
    get new_dwelling_url
    assert_response :success
  end

  test "should create dwelling" do
    assert_difference("Dwelling.count") do
      post dwellings_url, params: { dwelling: { name: @dwelling.name } }
    end

    assert_redirected_to dwelling_url(Dwelling.last)
  end

  test "should show dwelling" do
    get dwelling_url(@dwelling)
    assert_response :success
  end

  test "should get edit" do
    get edit_dwelling_url(@dwelling)
    assert_response :success
  end

  test "should update dwelling" do
    patch dwelling_url(@dwelling), params: { dwelling: { name: @dwelling.name } }
    assert_redirected_to dwelling_url(@dwelling)
  end

  test "should destroy dwelling" do
    assert_difference("Dwelling.count", -1) do
      delete dwelling_url(@dwelling)
    end

    assert_redirected_to dwellings_url
  end
end
