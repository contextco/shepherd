class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :rememberable,
         :validatable,
         :omniauthable, omniauth_providers: %i[google_oauth2]
end
