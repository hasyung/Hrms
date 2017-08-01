module Followable
  extend ActiveSupport::Concern

  included do
    field :followed_user_ids, type: Array, default: []
    field :followed_count, type: Integer, default: 0

    index _count: 1
  end

  def followed_by_user?(user)
    return false if user.blank?
    followed_user_ids.include?(user.id)
  end
end
