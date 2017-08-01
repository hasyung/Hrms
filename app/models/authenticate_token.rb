# == Schema Information
#
# Table name: authenticate_tokens
#
#  id          :integer          not null, primary key
#  token       :string(255)
#  expire_at   :datetime
#  employee_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class AuthenticateToken < ActiveRecord::Base
  belongs_to :employee

  def self.authorize!(access_token)
    token = find_by(token: access_token)
    return nil unless token

    if Time.now > token.expire_at
      token.destroy
      return nil
    end

    Employee.unscoped {token.employee}
  end

  def self.generate_token
    self.create(
      token: generate_access_token,
      expire_at: Time.now.advance(hours: 24)
    )
  end

  def refresh!
    self.update(expire_at: Time.now.advance(hours: 24))
  end

  private
  def self.generate_access_token
    SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')
  end
end
