# 疗养假
class Flow::RecuperateLeave < Flow
  include Workflowable
  include Leaveable

  ATTRIBUTES = [:start_time, :end_time, :vacation_days, :reason]

  store :form_data, :accessors => ATTRIBUTES
end
