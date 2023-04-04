require_relative './auth/auth.rb'
require_relative './files/files.rb'

module Laboratoire
    include Auth
    include Files
end