# == Schema Information
#
# Table name: schedules
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  display_name :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Schedule < ActiveRecord::Base
	has_many :positions
end
