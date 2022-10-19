class Part < ApplicationRecord
  belongs_to :xml_file
  # serialize :part_json, JSON
end
