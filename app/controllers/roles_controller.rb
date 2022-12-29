class RolesController < ApplicationController
  before_action :init_service!

  def index
    @roles = @service.index
  end

  def new
    @role = @service.new
  end

  def create
    @role = @service.create
    if @role.errors.any?
      render :new
    else
      redirect_to roles_path, notice: "Role created successfully"
    end
  end

  def show
    @role = @service.show
  end

  def edit
    @role = @service.edit
  end

  def update
    @role = @service.update
    if @role.errors.any?
      render :new
    else
      redirect_to roles_path, notice: "Role updated successfully"
    end
  end

  def destroy
    @service.destroy
    redirect_to roles_path, notice: "Role Deleted"
  end

  private
    def init_service!
      authorize(Role)
      @service = RolesService.new(request, params, current_user)
    end
end
