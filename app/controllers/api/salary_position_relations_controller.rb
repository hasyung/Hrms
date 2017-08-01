class Api::SalaryPositionRelationsController < ApplicationController

  def index
    @salary_position_relations = SalaryPositionRelation.includes(:salary)
    @positions_hash = Position.includes(:department).where(id: @salary_position_relations.flat_map(&:position_ids).uniq).index_by(&:id)
  end

  def update
    @salary_position_relation = SalaryPositionRelation.find(params[:id])

    unless @salary_position_relation.update(salary_position_relation_params)
      return render json: {messages: '修改失败'}, status: 400
    end
  end

  private
  def salary_position_relation_params
    params.permit(:salary_id, position_ids: [])
  end
end