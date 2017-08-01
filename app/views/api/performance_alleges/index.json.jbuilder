json.alleges @alleges do |allege|
  json.partial! 'api/performance_alleges/allege', allege: allege, attachments: allege.attachments
end