# == Schema Information
#
# Table name: code_tables
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  display_name :string(255)
#  type         :string(255)
#  level        :integer          default("0")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class CodeTable::Gender < CodeTable
  def en_name
    return "male" if self.display_name == '男' 
    return "female"
  end
end
