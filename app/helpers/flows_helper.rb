module FlowsHelper
  def t_workflow_state(flow, workflow_state)
    I18n.t("#{flow.class.to_s.underscore.sub('/', '.')}.event.#{workflow_state}")
  end
end