class DinnerRecordStat < ActiveRecord::Base
  serialize :airline_pos_list, Array
  serialize :political_pos_list, Array
end
