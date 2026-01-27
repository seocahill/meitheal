require "test_helper"

class FundingOpportunitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @editor = users(:editor)
    @viewer = users(:viewer)
    @opportunity = funding_opportunities(:arts_council_grant)
  end

  # Public access
  test "index is accessible to public" do
    get funding_opportunities_path
    assert_response :success
  end

  test "index shows open opportunities" do
    get funding_opportunities_path
    assert_response :success
    assert_includes response.body, @opportunity.title
  end

  test "show is accessible to public" do
    get funding_opportunity_path(@opportunity)
    assert_response :success
    assert_includes response.body, @opportunity.title
  end

  # Editor access for CRUD
  test "new requires editor role" do
    sign_in_as(@viewer)
    get new_funding_opportunity_path
    assert_redirected_to root_path
  end

  test "editor can access new form" do
    sign_in_as(@editor)
    get new_funding_opportunity_path
    assert_response :success
  end

  test "editor can create opportunity" do
    sign_in_as(@editor)
    assert_difference "FundingOpportunity.count" do
      post funding_opportunities_path, params: {
        funding_opportunity: {
          title: "New Grant",
          organization: "Culture Ireland",
          deadline: 1.month.from_now,
          description: "A great opportunity"
        }
      }
    end
    assert_redirected_to funding_opportunity_path(FundingOpportunity.last)
  end

  test "viewer cannot create opportunity" do
    sign_in_as(@viewer)
    assert_no_difference "FundingOpportunity.count" do
      post funding_opportunities_path, params: {
        funding_opportunity: {
          title: "New Grant",
          organization: "Culture Ireland",
          deadline: 1.month.from_now
        }
      }
    end
    assert_redirected_to root_path
  end

  test "editor can edit opportunity" do
    sign_in_as(@editor)
    get edit_funding_opportunity_path(@opportunity)
    assert_response :success
  end

  test "editor can update opportunity" do
    sign_in_as(@editor)
    patch funding_opportunity_path(@opportunity), params: {
      funding_opportunity: { title: "Updated Title" }
    }
    assert_redirected_to funding_opportunity_path(@opportunity)
    @opportunity.reload
    assert_equal "Updated Title", @opportunity.title
  end

  test "editor can destroy opportunity" do
    sign_in_as(@editor)
    assert_difference "FundingOpportunity.count", -1 do
      delete funding_opportunity_path(@opportunity)
    end
    assert_redirected_to funding_opportunities_path
  end
end
