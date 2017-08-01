class Api::PositionChangesController < ApplicationController
  include ExceptionHandler

  skip_before_action :check_action_register, only: [:show]
  skip_before_action :check_permission, only: [:show]

  def index
    result = parse_query_params!('position_audit')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values
    audit_conditions, position_conditions = [], []
    conditions.each{|condition|condition[0].include?('audits') ? audit_conditions << condition : position_conditions << condition}
    if position_conditions.blank?
      @audits = Audit.positions
    else
      positions = Position.unscoped.joins(relations)
      position_conditions.each{|condition| positions = positions.where(condition)}
      position_ids = positions.map(&:id)
      @audits = Audit.positions.where("(auditable_type = 'Position' AND auditable_id in (?)) OR (associated_type = 'Position' AND associated_id in (?))", position_ids, position_ids).order(sorts)
    end
    audit_conditions.each do |condition|
      @audits = @audits.where(condition)
    end unless audit_conditions.blank?
    @audits = set_page_meta @audits, page
    render template: '/api/position_changes/index'
  end

  def show
    @audit = Audit.find(params[:id])
    @position = Position.unscoped{@audit.associated || @audit.auditable}
    render template: '/api/position_changes/show'
  end

  private

  def get_page
    page = {}
    page_params = {page: params.delete("page"), per_page: params.delete("per_page")}
    if page_params["page"].present?
      page[:page] = page_params["page"].to_i
    else
      page[:page] = QuerySetting['default']['page']
    end
    if page_params["per_page"].present?
      page[:per_page] = page_params["per_page"].to_i
    else
      page[:per_page] = QuerySetting['default']['per_page']
    end
    page
  end

end
