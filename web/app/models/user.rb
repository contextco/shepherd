# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :rememberable,
         :validatable,
         :omniauthable, omniauth_providers: %i[google_oauth2]

  belongs_to :team, optional: true
  has_many :ssh_public_keys, class_name: "SSHPublicKey", dependent: :destroy

  enum :role, { user: 0, admin: 1 }

  class << self
    def from_omniauth!(access_token)
      data = access_token.info
      user = User.where(email: data["email"]).first

      if user
        user.update!(
          name: data["name"],
          first_name: data["first_name"],
          last_name: data["last_name"],
          profile_picture_url: data["image"]
        )
        return user
      end

      ActiveRecord::Base.transaction do
        team = Team.create!
        user = create_user_from_omniauth(team, data)
      end

      user
    end

    private

    def create_user_from_omniauth(team, data)
      team.users.create!(
        name: data["name"],
        email: data["email"],
        first_name: data["first_name"],
        last_name: data["last_name"],
        profile_picture_url: data["image"],
        password: Devise.friendly_token[0, 20]
        )
    end
  end
end
