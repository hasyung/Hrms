#产假(母乳喂养)
class Flow::MaternityLeaveBreastFeeding < Flow
  include Workflowable
  include MaternityLeaveable
  include Leaveable  

  def self.initiator(params)
    user_id = params[:receptor_id] || params[:sponsor_id]
    
    Employee.find(user_id).is_female?
  end
end