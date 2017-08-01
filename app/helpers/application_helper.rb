module ApplicationHelper
  def judge_static_source_host
    Rails.env.production? ? "" : Setting.static_source_host
  end
end
