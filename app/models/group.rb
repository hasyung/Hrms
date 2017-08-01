# == Schema Information
#
# Table name: groups
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :string(255)
#  bit_value   :string(255)      default("0")
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_groups_on_bit_value  (bit_value)
#  index_groups_on_name       (name)
#

class Group < ActiveRecord::Base
  validates_presence_of :name, :description, :bit_value
  validates_uniqueness_of :name
end
