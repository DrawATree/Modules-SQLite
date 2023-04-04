require_relative '../bd/bd.rb'

module Laboratoire
    module Auth
        include Bd
        
        def sha256(value)
            nil if value.nil? || value.empty?
        
            OpenSSL::HMAC.hexdigest("sha256", SHA_KEY, value)
        end

        def login(username, password)
            list = JSON.parse(Bd::select("* FROM users"), {symbolize_names: true})

            list.select! do |item|
                username == item[:name] && sha256(password) == item[:password]
            end.first

            return list.to_json
        end
    end
end