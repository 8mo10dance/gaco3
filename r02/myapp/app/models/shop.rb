class Shop < ApplicationRecord
  belongs_to :contract
  has_many :jobs
  has_many :publish_logs
end
