# == Schema Information
#
# Table name: positions
#
#  id                 :integer          not null, primary key
#  pinyin_name        :string(255)
#  pinyin_index       :string(255)
#  name               :string(255)
#  budgeted_staffing  :integer
#  oa_file_no         :string(255)
#  post_type          :string(255)
#  remark             :string(255)
#  department_id      :integer
#  channel_id         :integer
#  schedule_id        :integer
#  category_id        :integer
#  position_nature_id :integer
#  employees_count    :integer          default("0")
#  flow_bit_value     :string(255)      default("0")
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_positions_on_flow_bit_value  (flow_bit_value)
#

require 'rails_helper'

RSpec.describe Position, :type => :model do
end
