class User < ApplicationRecord
  extend Enumerize

  enumerize :active, in: { inactive: 0, active: 1 }

  def hoge
    # TODO
  end

  def call
    hoge value: 1, x: 0
    hoge value: 1.1
    hoge value: '1.1'
  end
end
