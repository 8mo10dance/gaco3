class Shop < ApplicationRecord
  belongs_to :contract
  has_many :jobs
  has_many :publish_logs

  scope :with_job, -> { where.has { exists(Job.where.has { shop_id == shop.id }) } }

  scope :with_contract, -> { where.has { exists(Contract.where.has { id == shops.contract_id }) } }

  scope :with_job_and_contract, -> { with_job.with_contract }
end
