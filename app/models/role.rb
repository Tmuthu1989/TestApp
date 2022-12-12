class Role < ApplicationRecord
	scope :all_roles, -> {where.not(name: "Super Admin")}
	has_many :users, dependent: :destroy
	validates :name, uniqueness: true
	NO_ACCESS = 0
	READ = 1
	READ_AND_WRITE = 2
	store_attribute :permissions, :settings, :integer, default: NO_ACCESS
	store_attribute :permissions, :user_management, :integer, default: NO_ACCESS
	store_attribute :permissions, :roles, :integer, default: NO_ACCESS
	store_attribute :permissions, :xml_files, :integer, default: NO_ACCESS
	store_attribute :permissions, :boms, :integer, default: NO_ACCESS
	store_attribute :permissions, :parts, :integer, default: NO_ACCESS
	store_attribute :permissions, :documents, :integer, default: NO_ACCESS
	store_attribute :permissions, :document_uploads, :integer, default: NO_ACCESS

end
