class ApplicationPolicy
  attr_reader :user, :record, :role

  def initialize(user, record)
    @user = user
    @record = record
  end

  def read?
    can_read?(role)
  end

  def write?
    can_write?(role)
  end

  def index?
    false
  end

  def show?
    scope.where(:id => record.id).exists?
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  def can_read?(role)
    [Role::READ, Role::READ_AND_WRITE].include?(role)
  end

  def can_write?(role)
    role === Role::READ_AND_WRITE
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope
    end
  end
end
