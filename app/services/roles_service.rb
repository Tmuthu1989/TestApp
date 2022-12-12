class RolesService < BaseService
	attr_accessor :role
	def initialize(request, params, user)
		super(request, params, user)
		self.role = get_role
	end

	def index
		Role.where.not(name: "Super Admin").page(params[:page])
	end

	def new
		Role.new
	end

	def create
		Role.create(role_params)
	end

	def show
		role
	end

	def edit
		role
	end

	def update
		@role.update(role_params)
		@role.reload
	end

	def destroy
		@role.destroy
	end

	private
		def get_role
			Role.find_by(id: params[:id])
		end

		def role_params
			params.require(:role).permit(:name, :settings, :roles, :user_management, :xml_files, :parts, :boms, :documents, :document_uploads)
		end
end