require 'rails_helper'

RSpec.describe Api::DinnerSettlesController, type: :controller do
  render_views

  let(:json) {JSON.parse(response.body)}

  before(:each) do
    #
  end

  after(:each) do
    puts JSON.pretty_generate(json)
  end

  describe "with action" do
    #
  end
end
