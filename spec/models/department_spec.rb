# == Schema Information
#
# Table name: departments
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  pinyin_name     :string(255)
#  pinyin_index    :string(255)
#  serial_number   :string(255)
#  depth           :integer
#  childrens_count :integer          default("0")
#  grade_id        :integer          default("0")
#  nature_id       :integer
#  parent_id       :integer
#  childrens_index :integer          default("0")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'rails_helper'

RSpec.describe Department, :type => :model do
  before(:each) do
  end

  
end
