json.education_experience do
  json.partial! 'api/me/education_experiences/basic', education_experience: @education_experience
end