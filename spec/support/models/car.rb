# frozen_string_literal: true

class Car < ApplicationRecord

  belongs_to :user, counter_cache: true

  has_one  :insurance, dependent: :destroy
  has_many :drivers, dependent: :destroy

end
