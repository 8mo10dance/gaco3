class User < ApplicationRecord
  extend Enumerize

  enumerize :active, in: { inactive: 0, active: 1 }
end
