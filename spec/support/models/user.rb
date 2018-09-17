# frozen_string_literal: true

class User < ApplicationRecord

  attr_accessor :random

  has_one :license
  has_one :bio, dependent: :destroy
  has_many :cars, dependent: :destroy
  has_many :comments

  before_unarchive :randomize_before!
  after_archive :randomize_after!

  private

  def randomize_before!
    self.random = 3
  end

  def randomize_after!
    self.random = 5
  end

end
