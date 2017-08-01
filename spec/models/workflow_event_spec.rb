# == Schema Information
#
# Table name: workflow_events
#
#  id                  :integer          not null, primary key
#  flow_id             :string(255)
#  workflow_state      :string(255)
#  reviewer_id         :integer
#  reviewer_no         :string(255)
#  reviewer_name       :string(255)
#  reviewer_position   :string(255)
#  reviewer_department :string(255)
#  desc                :string(255)
#  event               :string(255)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

require 'rails_helper'

RSpec.describe WorkflowEvent, :type => :model do
end
