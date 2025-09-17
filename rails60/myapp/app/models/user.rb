class User < ApplicationRecord
  extend Enumerize

  enumerize :active, in: { inactive: 0, active: 1 }

  def hoge
    # TODO
  end

  def call
    hoge(1)
    hoge(1.1)
    hoge('1.1')
  end
end
