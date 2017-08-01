module MaternityLeaveable
  extend ActiveSupport::Concern
  include Leaveable

  ATTRIBUTES = [:start_time, :end_time, :vacation_days, :reason]

  included do 
    store :form_data, :accessors => ATTRIBUTES
    # validates :start_time, :end_time, :reason, :vacation_days, presence: true
  end
end