class UsersController < ApplicationController
  before_action :init_service!

  def index
    @users = @service.index
  end

  def new
    @user = @service.new
  end

  def create
    @user = @service.create
    if @user.errors.any?
      render :new
    else
      redirect_to users_path, notice: "User created successfully"
    end
  end

  def show
    @user = @service.show
  end

  def edit
    @user = @service.edit
  end

  def update
    @user = @service.update
    if @user.errors.any?
      render :new
    else
      redirect_to users_path, notice: "User updated successfully"
    end
  end

  def destroy
    @service.destroy
    redirect_to users_path, notice: "User Deleted"
  end

  private
    def init_service!
      authorize(User)
      @service = UsersService.new(request, params, current_user)
    end
end
