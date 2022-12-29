class DocumentUploadPolicy < ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    can_read?(role)
  end

  def show?
    can_read?(role)
  end

  def create?
    can_write?(role)
  end

  def new?
    create?
  end

  def update?
    can_write?(role)
  end

  def edit?
    update?
  end

  def destroy?
    can_write?(role)
  end

  def re_process?
    can_write?(role)
  end

  def role
    user&.role&.document_uploads
  end

end
