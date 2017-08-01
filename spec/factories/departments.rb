# == Schema Information
#
# Table name: departments
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  pinyin_name     :string(255)
#  pinyin_index    :string(255)
#  serial_number   :string(255)
#  depth           :integer
#  childrens_count :integer          default("0")
#  grade_id        :integer          default("0")
#  nature_id       :integer
#  parent_id       :integer
#  childrens_index :integer          default("0")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

FactoryGirl.define do
  factory :department do
    name {Faker::Name.title}

    factory :root_department do
      parent_id 0
      depth 1
      serial_number '000'
    end

    factory :second_department do 
      depth 2
      serial_number '000001'
    end

    factory :third_department do 
      depth 3
      serial_number '000001001'
    end
  end
end
