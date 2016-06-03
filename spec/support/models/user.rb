class User < ActiveRecord::Base

  has_one :license
  has_one :bio, dependent: :destroy
  has_many :cars, dependent: :destroy
  has_many :comments

end
