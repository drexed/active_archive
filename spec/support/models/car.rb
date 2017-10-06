# frozen_string_literal: true

class Car < ActiveRecord::Base

  belongs_to :user

  has_one  :insurance, dependent: :destroy
  has_many :drivers, dependent: :destroy

end
