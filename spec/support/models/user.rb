# frozen_string_literal: true

class User < ApplicationRecord

  has_one :license
  has_one :bio, dependent: :destroy
  has_many :cars, dependent: :destroy
  has_many :comments

end
