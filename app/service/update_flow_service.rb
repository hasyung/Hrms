class UpdateFlowService
  def initialize(service_params)
    @event_params = service_params[:body]
    @reviewer = service_params[:current_user]
    @opinion = service_params[:opinion]
    @reviewer_ids = service_params[:reviewer_ids]
    @flow = service_params[:flow]
  end

  def call
    $redis.lock("WorkflowLock::#{@flow.type}::#{@flow.id}") do
      @flow.next_purpose(@opinion)

      update_reviewers_and_viewers
      notice_sponsor_and_receptor
      notice_current_reviewer # 用于更新前端该步处理人的流程通知
      notice_reviewers

      @flow
    end
  end

  def create_workflow_event
    master_position = @reviewer.master_position

    @flow.flow_nodes.create(
      reviewer_no: @reviewer.employee_no,
      reviewer_name: @reviewer.name,
      reviewer_id: @reviewer.id,
      reviewer_position: master_position.name,
      reviewer_department: master_position.department.full_name,
      body: @event_params,
    )
  end

  private
  def update_reviewers_and_viewers
    if @flow.reload.flow_end?
      @flow.viewer_ids |= @flow.reviewer_ids
      @flow.reviewer_ids = []
    else
      reviewer_ids = @flow.reviewer_ids
      reviewer_ids.delete_at(@flow.get_index_for(@reviewer.id))
      @flow.reviewer_ids = reviewer_ids
      @flow.reviewer_ids += @reviewer_ids
      @flow.viewer_ids |= [@reviewer.id]
    end
    @flow.viewer_ids = @flow.viewer_ids.uniq
    @flow.reviewer_ids = @flow.reviewer_ids.uniq

    @flow.save
  end

  def notice_sponsor_and_receptor
    name = Employee.unscoped.find(@flow.receptor_id).name
    if @flow.flow_end?
      message = I18n.t('flow.messages.end', employee_name: name, flow_name: @flow.name, state: @flow.t_current_state)
    else
      message = I18n.t('flow.messages.to_sponsor', reviewer: @reviewer.name, event: "已审批", flow_name: @flow.name)
    end

    # Notification.send_user_message(@flow.sponsor_id, @flow.type, message) unless @flow.sponsor.blank?
    # Notification.send_user_message(@flow.receptor_id, @flow.type, message) unless @flow.sponsor_id == @flow.receptor_id || @flow.receptor.blank?
  end

  def notice_reviewers
    unless @flow.reviewer_ids.empty?
      @flow.reviewer_ids.flatten.each do |employee_id|
        # Notification.send_workflow_messages(employee_id, @flow.type) unless Employee.find_by(id: employee_id).blank? 
      end
    end
  end

  def notice_current_reviewer
    # Notification.send_workflow_messages(@reviewer.id, @flow.type) unless @reviewer.blank?
  end
end
