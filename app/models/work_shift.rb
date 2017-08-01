class WorkShift < ActiveRecord::Base
	default_scope {where "end_time is null"}
	belongs_to :employee
end
