class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :role, optional: true
  encrypts :default_password
  before_validation :set_default_password
  validate :password_complexity
  attr_accessor :send_mail
  after_create :send_password_mail

  def password_complexity
    if password.present? && default_password.blank?
      if !password.match(/^(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#$%^&*()_+-|<>?~])/)
        errors.add :password, "Password must contain One capital, one small, one numeric and one special char"
      end
    end
  end

  def is_super_admin?
    self.role.name === "Super Admin"
  end

  def set_default_password
    if password.blank?
      pwd = ('0'..'z').to_a.shuffle.first(8).join
      self.password = pwd
      self.password_confirmation = pwd
      self.default_password = pwd
      self.send_mail = true
    end
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def send_password_mail
    UserMailer.send_password_mail(self).deliver_now if send_mail
  end
end
