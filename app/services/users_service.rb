class UsersService < BaseService
	attr_accessor :user
	def initialize(request, params, user)
		super(request, params, user)
		self.user = get_user
	end

	def index
		User.includes(:role).where.not(roles: {name: "Super Admin"}).page(params[:page])
	end

	def new
		User.new
	end

	def create
		User.create(user_params)
	end

	def show
		
	end

	def edit
		
	end

	def update
		@user.update(user_params)
	end

	def destroy
		@user.destroy
	end

	private
		def get_user
			User.find_by(id: params[:id])
		end

		def user_params
			params.require(:user).permit(:first_name, :last_name, :email, :role_id)
		end
end