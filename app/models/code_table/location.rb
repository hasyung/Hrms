# == Schema Information
#
# Table name: code_table_locations
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  display_name :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class CodeTable::Location < ActiveRecord::Base
  include Snapshotable
  include Pinyinable

  has_many :employees

  validates_presence_of :name
  validates_uniqueness_of :name
end
