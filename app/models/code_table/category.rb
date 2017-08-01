# == Schema Information
#
# Table name: code_table_categories
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  display_name :string(255)
#  key          :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class CodeTable::Category < ActiveRecord::Base
  include Pinyinable

  has_many :employees
  has_many :positions
end
