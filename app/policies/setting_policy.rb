class SettingPolicy < ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def read_settings?
    can_read?(role)
  end

  def write_settings?
    can_write?(role)
  end

  def role
    user&.role&.settings
  end

end
