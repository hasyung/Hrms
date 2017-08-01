# == Schema Information
#
# Table name: code_table_channels
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  display_name :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class CodeTable::Channel < ActiveRecord::Base
  include Pinyinable

  has_many :positions
  has_many :employees
end
