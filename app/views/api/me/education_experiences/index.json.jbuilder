json.education_experiences @education_experiences do |education_experience|
  json.partial! 'api/me/education_experiences/basic', education_experience: education_experience
end