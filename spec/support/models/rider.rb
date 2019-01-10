# frozen_string_literal: true

class Rider < ApplicationRecord

  belongs_to :requester, polymorphic: true

end
