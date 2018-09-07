# frozen_string_literal: true

class Comment < ApplicationRecord

  belongs_to :user, counter_cache: true

end
