class SalaryPositionRelation < ActiveRecord::Base
	serialize :position_ids, Array

	belongs_to :salary
end
