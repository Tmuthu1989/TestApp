class Part < ApplicationRecord
  belongs_to :xml_file
  before_save :set_odo_body
  scope :inwork, -> {where(state: "INWORK")}
  scope :pending, -> {where.not(status: AppConstants::FILE_STATUS[:success])}
  scope :success, -> {where(status: AppConstants::FILE_STATUS[:success])}
  scope :added, -> {where(part_type: "AddedParts")}
  scope :changed, -> {where(part_type: "ChangedParts")}
  scope :unchanged, -> {where(part_type: "UnchangedParts")}
  scope :deleleted, -> {where(part_type: "DeletedParts")}

  def self.load_parts(xml_file)
    json_obj = xml_file.json_obj
    if json_obj
      json_content = json_obj["COLLECTION"]
      transaction_obj = json_content["Release"]["Transaction"]
      ["AddedParts", "ChangedParts", "UnchangedParts", "DeletedParts"].each do |part_type|
        if json_content[part_type].present? && json_content[part_type]["Part"].present?
          parts = json_content[part_type]["Part"]
          parts = [parts] if parts.class.to_s != "Array"
          parts.each do |part|
            xml_file.parts.create(part_name: part["Name"], part_number: part["Number"], part_type: part_type, part_json: part, part_xml: part.to_xml(root: :Part), created_by: transaction_obj["CreatedBy"], transaction_obj: transaction_obj, state: part["State"])
          end
        end
      end
    end
  end

  def validate_part
    part = self.part_json.to_obj
    error = {}
    length = part.LENGTH.to_s.split(" ")[0].to_s.gsub("E", '')
    height = part.HEIGHT.to_s.split(" ")[0].to_s.gsub("E", '')
    width = part.WIDTH.to_s.split(" ")[0].to_s.gsub("E", '')
    mass = (part.MASS.present? ? part.MASS.to_s[0...-2].strip : "").to_s.split(" ")[0].to_s.gsub("E", '')
    error[:classification_code] = true if part.CLASSIFICATION_CODE.to_s.strip.blank?
    error[:part_number] = true if part.Number.to_s.strip.blank?
    error[:part_name] = true if part.Name.blank?
    error[:created_by] = true if self.created_by.blank?
    error[:updated_by] = true if part.LastChangedBy.blank?
    error[:length] = true if length.present? && length.to_s.count("a-zA-Z") > 0
    error[:width] = true if width.present? && width.to_s.count("a-zA-Z") > 0
    error[:height] = true if height.present? && height.to_s.count("a-zA-Z") > 0
    error[:mass] = true if mass.present? && mass.to_s.count("a-zA-Z") > 0
    self.error = error
  end

  def set_odo_body
    validate_part
    part = self.part_json.to_obj
    odoo_part_number = "#{part.CLASSIFICATION_CODE}#{part.Version}"
    body = {
      default_code: part.Number.to_s.strip,
      part: odoo_part_number,
      revision: part.Version,
      name: part.Name,
      part_type: part.PartType,
      material: part.MATERIAL,
      length: part.LENGTH,
      height: part.HEIGHT,
      breadth: part.WIDTH,
      weight: part.MASS.present? ? part.MASS.to_s[0...-2].strip : "",
      lifecycle_status: part.State,
      manufacturer: part.MANUFACTURER,
      manufacturer_ref: part.MANUFACTURER_REF,
      name_a: part.NAME_A,
      name_d: part.NAME_D,
      name_f: part.NAME_F,
      type: part.TYPE,
      classification_code: part.CLASSIFICATION_CODE,
      created_by_from_api: self.created_by,
      updated_by_from_api: part.LastChangedBy
    }
    self.odoo_part_number = odoo_part_number
    self.odoo_body = body
  end

  def self.process_parts(xml_file)
    begin
      @setting = Setting.last
      parts = xml_file.parts.pending.where(error: {}).group_by(&:part_type)
      @odoo_service = OdooService.new(@setting, xml_file.id)
      added_parts = []
      added_parts = parts["AddedParts"].map { |e|  e.odoo_body } if parts["AddedParts"].present?
      other_parts = []
      other_parts = parts["ChangedParts"].map { |e|  e.odoo_body } if parts["ChangedParts"].present?
      other_parts += parts["UnchangedParts"].map { |e|  e.odoo_body } if parts["UnchangedParts"].present?
      deleleted_parts = parts["DeletedParts"].map { |e|  e.odoo_body["part"] } if parts["DeletedParts"].present?
      process_added_parts(added_parts) if added_parts.present?
      process_other_parts(other_parts) if other_parts.present?
      process_deleted_parts(deleleted_parts) if deleleted_parts.present?
      "XML File parts processed"  
    rescue StandardError => e
      error = {
        error_type: "StandardError",
        title: e,
        message: e.message,
        backtrace: e.backtrace
      }
      HttpRequest.create(error: error, xml_file_id: xml_file.id)
    end
  end

  def self.process_added_parts(parts, part_types=["AddedParts"], processed_by="Create Products")
    response = @odoo_service.create_products(parts)
    Part.where(odoo_part_number: parts.map{|part| part["part"]}, part_type: part_types).update_all(status: AppConstants::FILE_STATUS[:success], processed_by: processed_by) if response.present?
  end

  def self.process_other_parts(parts)
    parts_to_be_updated = []
    added_parts = []
    existing_products = @odoo_service.get_products(parts.map{|part| part["part"]})
    existing_products.map { |product| product.default_code.to_s }
    parts.each do |part|
      if existing_products.include?(part["part"])
        parts_to_be_updated << part
      else
        added_parts << part
      end
    end
    process_added_parts(added_parts, ["ChangedParts", "UnchangedParts"], "Created products by Update Products") if added_parts.present?
    if parts_to_be_updated.present?
      response = @odoo_service.update_products(parts_to_be_updated)
      Part.where(odoo_part_number: parts_to_be_updated.map{|part| part["part"]}, part_type: ["ChangedParts", "UnchangedParts"]).update_all(status: AppConstants::FILE_STATUS[:success], processed_by: "Update Products") if response.present?
    end
  end

  def self.process_deleted_parts(parts)
    response = @odoo_service.delete_products(parts)
    Part.where(odoo_part_number: parts.map{|part| part["part"]}, part_type: "DeletedParts").update_all(status: AppConstants::FILE_STATUS[:success], processed_by: "Delete Products") if response.present?
  end
end
