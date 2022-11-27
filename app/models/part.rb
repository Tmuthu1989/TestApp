class Part < ApplicationRecord
  belongs_to :xml_file
  before_save :set_odo_body

  def set_odo_body
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
      parts = xml_file.parts.where.not(status: AppConstants::FILE_STATUS[:success]).group_by(&:part_type)
      @odoo_service = OdooService.new(@setting, xml_file.id)
      added_parts = []
      added_parts = parts["AddedParts"].map { |e|  e.odoo_body } if parts["AddedParts"].present?
      other_parts = []
      other_parts = parts["ChangedParts"].map { |e|  e.odoo_body } if parts["ChangedParts"].present?
      other_parts += parts["UnchangedParts"].map { |e|  e.odoo_body } if parts["UnchangedParts"].present?
      deleleted_parts = parts["DeletedParts"].map { |e|  e.odoo_body["part"] } if parts["DeletedParts"].present?
      @setting = Setting.last
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
    Part.where(odoo_part_number: parts.map{|part| part["part"]}, part_type: part_types).update_all(status: AppConstants::FILE_STATUS[:success], processed_by: processed_by)
  end

  def self.process_other_parts(parts)
    parts_to_be_updated = []
    added_parts = []
    parts.each do |part|
      existing_products = @odoo_service.get_products({part: [part["part"]]})
      if existing_products.present?
        parts_to_be_updated << part
      else
        added_parts << part
      end
    end
    process_added_parts(added_parts, ["ChangedParts", "UnchangedParts"], "Update Products") if added_parts.present?
    if parts_to_be_updated.present?
      @odoo_service.update_products(parts_to_be_updated)
      Part.where(odoo_part_number: parts_to_be_updated.map{|part| part["part"]}, part_type: ["ChangedParts", "UnchangedParts"]).update_all(status: AppConstants::FILE_STATUS[:success], processed_by: "Update Products")
    end
  end

  def self.process_deleted_parts(parts)
    @odoo_service.delete_products(parts)
    Part.where(odoo_part_number: parts.map{|part| part["part"]}, part_type: "DeletedParts").update_all(status: AppConstants::FILE_STATUS[:success], processed_by: "Delete Products")
  end
end
