class Api::StatController < ApplicationController

  def index
    performace = [
      {优秀:3},
      {良好:2},
      {合格:0},
      {待改进:0},
      {不合格:0}
    ]

    render json: {performace: performace}
  end
end
