module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound do
      render json: {messages: "资源不存在或是已经删除"}, status: :not_found
    end
  end
end
