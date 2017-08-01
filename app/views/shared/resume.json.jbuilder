json.employee do
  json.id @employee.id
  json.name @employee.name
  json.native_place @employee.native_place
  json.birth_place @employee.birth_place
  json.birthday @employee.birthday
  json.identity_no @employee.identity_no
  json.nationality @employee.nationality
  json.nation @employee.nation
  json.gender @employee.gender
  json.marital_status @employee.marital_status
  #json.english_level @employee.english_level
  json.school @employee.school
  json.major @employee.major
  json.education_background @employee.education_background
  json.degree @employee.degree
  json.graduate_date @employee.graduate_date
  json.join_party_date @employee.join_party_date
  json.political_status_id @employee.political_status_id
  json.star @employee.star


  json.contact @employee.contact
  json.personal_info @employee.personal_info
  json.work_experiences @employee.work_experiences
  json.family_members @employee.family_members
  json.education_experiences @employee.education_experiences do |edu|
    json.school edu.school
    json.major edu.major
    json.admission_date edu.admission_date
    json.graduation_date edu.graduation_date
    json.education_background edu.education_background
    json.degree edu.degree
    json.witness edu.witness
    json.category edu.category
  end

  json.languages @languages do |language|
    json.name  language.name
    json.grade language.grade
  end
  json.technical @employee.technical
end
