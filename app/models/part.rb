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

  def pending?
    status != AppConstants::FILE_STATUS[:success]
  end

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
    part = self.odoo_body.to_obj
    error = {}
    length = part.length.to_s.split(" ")[0].to_s.gsub("E", '')
    height = part.height.to_s.split(" ")[0].to_s.gsub("E", '')
    width = part.breadth.to_s.split(" ")[0].to_s.gsub("E", '')
    mass = (part.weight.present? ? part.weight.to_s[0...-2].strip : "").to_s.split(" ")[0].to_s.gsub("E", '')
    error[:classification_code] = true if part.classification_code.to_s.strip.blank?
    error[:part_number] = true if part.default_code.to_s.strip.blank?
    error[:part_name] = true if part.name.blank?
    error[:created_by] = true if part.created_by_from_api.blank?
    error[:updated_by] = true if part.updated_by_from_api.blank?
    error[:length] = true if length.present? && length.to_s.count("a-zA-Z") > 0
    error[:width] = true if width.present? && width.to_s.count("a-zA-Z") > 0
    error[:height] = true if height.present? && height.to_s.count("a-zA-Z") > 0
    error[:mass] = true if mass.present? && mass.to_s.count("a-zA-Z") > 0
    self.odoo_part_number = part.part
    self.error = error
  end

  def set_odo_body
    if self.id.blank?
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
    validate_part
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
    response, error = @odoo_service.create_products(parts)
    if error.present?
      Part.where(odoo_part_number: parts.map{|part| part["part"]}, part_type: part_types).update_all(status: AppConstants::FILE_STATUS[:failed], processed_by: processed_by, error: {server_error: error}, processed_by: processed_by, odoo_type: "Add")
    else
      create_parts = update_error_list(parts.map{|part| part["part"]}, response, processed_by) if response.result.error_list.present?
      Part.where(odoo_part_number: create_parts, part_type: part_types).update_all(status: AppConstants::FILE_STATUS[:success], processed_by: processed_by, odoo_type: "Add") if response.present? && response.error.blank? && create_parts.present?
    end
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
    process_added_parts(added_parts, ["ChangedParts", "UnchangedParts"], "Created products by Update") if added_parts.present?
    if parts_to_be_updated.present?
      response, error = @odoo_service.update_products(parts_to_be_updated)
      if error.present?
        Part.where(odoo_part_number: parts_to_be_updated.map{|part| part["part"]}, part_type: ["ChangedParts", "UnchangedParts"]).update_all(status: AppConstants::FILE_STATUS[:failed], processed_by: "Update Products", error: {server_error: error})
      else
        update_parts = update_error_list(parts_to_be_updated.map{|part| part["part"]}, response, "Update Products") if response.result.error_list.present?
        Part.where(odoo_part_number: update_parts, part_type: ["ChangedParts", "UnchangedParts"]).update_all(status: AppConstants::FILE_STATUS[:success], processed_by: "Update Products", odoo_type: "Update") if response.present? && response.error.blank? && update_parts.present?
      end
    end
  end

  def self.process_deleted_parts(parts)
    response, error = @odoo_service.delete_products(parts)
    if error.present?
      Part.where(odoo_part_number: parts.map{|part| part["part"]}, part_type: "DeletedParts").update_all(status: AppConstants::FILE_STATUS[:failed], processed_by: "Delete Products", error: {server_error: error})
    else
      delete_parts = update_error_list(parts.map{|part| part["part"]}, response, "Delete Products") if response.result.error_list.present?
      Part.where(odoo_part_number: delete_parts, part_type: "DeletedParts").update_all(status: AppConstants::FILE_STATUS[:success], processed_by: "Delete Products") if response.present? && response.error.blank?
    end
  end

  def self.update_error_list(parts, response, processed_by)
    error_msg = response.result.logs[0].to_s.split(":")[1].to_s.gsub(" , msg", "")
    error_parts = Part.where(part_number: response.result.error_list)
    new_parts = parts - error_parts.map { |e| e.odoo_part_number }
    error_parts.update_all(error: {server_error: error_msg}, processed_by: processed_by, status: AppConstants::FILE_STATUS[:success])
    new_parts
  end

  def process_part
    if !self.error.present? || (self.error.present? && self.error["server_error"].present?)
      @setting = Setting.last
      @odoo_service = OdooService.new(@setting, self.xml_file_id)
      existing_products = @odoo_service.get_products([self.odoo_part_number])
      existing_products.map { |product| product.default_code.to_s }
      if self.part_type === "AddedParts" || !existing_products.include?(self.odoo_part_number)
        response, error = @odoo_service.create_products([self.odoo_body])
        if error
          self.update(status: AppConstants::FILE_STATUS[:failed], processed_by: "Create products#{ 'by Update' if self.part_type != 'AddedParts'}", error: {server_error: error}, odoo_type: "Add") if response.present?
        else
          part = Part.update_error_list([self.odoo_body], response, processed_by) if response.result.error_list.present?
          self.update(status: AppConstants::FILE_STATUS[:success], processed_by: "Create products#{ 'by Update' if self.part_type != 'AddedParts'}", odoo_type: "Add", error: {}) if response.present? && part.present?
        end
      elsif ["ChangedParts", "UnchangedParts"].include?(self.part_type)
        response, error = @odoo_service.update_products(parts_to_be_updated)
        if error
          self.update(status: AppConstants::FILE_STATUS[:failed], processed_by: "Update Products", odoo_type: "Update", error: {server_error: error}) if response.present?
        else
          part = Part.update_error_list([self.odoo_body], response, processed_by) if response.result.error_list.present?
          self.update(status: AppConstants::FILE_STATUS[:success], processed_by: "Update Products", odoo_type: "Update", error: {}) if response.present? && part.present?
        end
      else
        response, error = @odoo_service.delete_products([self.odoo_part_number])
        if error
          self.update(status: AppConstants::FILE_STATUS[:failed], processed_by: "Delete Products", odoo_type: "Delete", error: {server_error: error}) if response.present?
        else
          part = Part.update_error_list([self.odoo_body], response, processed_by) if response.result.error_list.present?
          self.update(status: AppConstants::FILE_STATUS[:success], processed_by: "Delete Products", odoo_type: "Delete", error: {}) if response.present? && part.present?
        end
      end
    end
  end
end
