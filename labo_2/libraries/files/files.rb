require_relative '../bd/bd.rb'
require 'securerandom'
require 'date'

module Laboratoire
    module Files
        include Bd
        ##Will be called when ->     get '/files'
        def list_all(table, user)

            list = JSON.parse(Bd::select("* FROM #{table};"), {symbolize_names: true})

            Dir.glob("./files/**").each {|f| File.delete(f)} if list.empty?

            list = list.each do |item|
                #if password -> true, else false
                item[:pass].nil? ? item[:private] = false : item[:private] = true
                #if user_id == @user[:id] -> true, else false
                if user
                    item[:user_id] == user["id"] ? item[:mine] = true : item[:mine] = false
                else
                    item[:mine] = false
                end
                
                item.delete(:pass)
            end
            
            if user
                list.sort_by! do |item|
                    [
                        (user["id"] != item[:user_id]).to_s,
                        (DateTime.now - DateTime.parse(item[:timestamp])).to_i
                    ]
                end
            else
                list.sort_by! do |item|
                    [ 
                        (DateTime.now - DateTime.parse(item[:timestamp])).to_i,
                        item[:name]
                    ]
                end
                    
            end
            
            return [200, list.to_json]
        end

        ##Will be called when ->     get '/files/:hash'
        def list_one(table, hash, pass, user)

            return [400, "Not an hash"] unless hash.length == 8

            return [404, "Item not found"] unless File.exists?("./files/#{hash}.txt")

            ##put hash of SELECT fonction in list
            list = JSON.parse(Bd::select("* FROM #{table} WHERE hash = '#{hash}';"), {symbolize_names: true})

            return [404, "Sorry, item not found"] if list.empty?

            list = list.each do |item|
                #if password -> true, else false
                item[:pass].nil? ? item[:private] = false : item[:private] = true

                
                if user
                    item[:user_id] == user["id"] ? item[:mine] = true : item[:mine] = false
                else
                    item[:mine] = false
                end

                unless item[:mine] == true || item[:pass].nil?
                    return [401, "Something went wrong"] unless item[:pass] == sha256(pass)
                end

                item.delete(:pass)
            end

            return [200, "./files/#{list[0][:hash]}.txt"]
        end

        ##Will be called when ->     post '/files'
        def create(user, options, filepass, newFile)

            ##CREATING THE FILE
            fileContent = newFile["tempfile"].read
            return [400, "#{newFile["filename"]} contains nothing."] if fileContent.empty?

            locations = []

            fileContent.split("\n").each do |fileContent|
                ##INSERTING THE LINK OF THE FILE TO USER IN BD
                user_id = user["id"]
                hash = SecureRandom.alphanumeric(8)
                name = newFile["filename"]
                timestamp = DateTime.now().new_offset("-05:00").strftime('%F %T')
                
                optionsParams = " "
                
                optionsParams << "--root #{options["root"]} " unless options["root"].empty?            
                optionsParams << "--ignore #{options["ignore"]} " unless options["ignore"].empty?           
                optionsParams << "--html " unless options["html"].empty?           
                optionsParams << "--markdown " unless options["markdown"].empty?      

                File.new("./files/#{hash}.txt",'w') 
                
                theCommandWhenRight = system("hget #{fileContent} #{optionsParams} > ./files/#{hash}.txt") 
                
                File.delete("./files/#{hash}.txt") unless theCommandWhenRight
                return [400, "Something went wrong while writing the file"] unless t
                
                ##LINKING THE FILE TO THE USER
                Bd::insert("files VALUES (#{user_id}, '#{hash}', '#{name}', '#{timestamp}', NULL);") if filepass.empty?
                Bd::insert("files VALUES (#{user_id}, '#{hash}', '#{name}', '#{timestamp}', '#{sha256(filepass)}');") unless filepass.empty?
                
                locations << "./files/#{hash}.txt"
            end

            return [201, locations]
        end

        ##Will be called when ->     patch '/files/:hash'
        def modify(table, hash, user, newPass)
            return [404, "File not found"] unless File.exists?("./files/#{hash}.txt")

            list = JSON.parse(Bd::select("* FROM #{table} WHERE hash = '#{hash}';"), {symbolize_names: true})[0]

            return [404, "File not found"] if list.empty?

            return [401, "Not the file owner"] unless list[:user_id] == user["id"]

            query = "#{table} SET pass = '#{sha256(newPass)}' WHERE hash = '#{hash}';" unless newPass.empty?
            query = "#{table} SET pass = NULL WHERE hash = '#{hash}';" if newPass.empty?
            Bd::update(query)

            return [204]
        end

        ##Will be called when ->     delete '/files/:hash'
        def destroy(table, hash, user)
            
            return [404, "File not found"] unless File.exists?("./files/#{hash}.txt")

            list = JSON.parse(Bd::select("* FROM #{table} WHERE hash = '#{hash}';"), {symbolize_names: true})
            
            return [404, "File not found"] if list.empty?

            return [401, "Not the file owner"] unless list[0][:user_id] == user["id"]
            
            response = JSON.parse(Bd::delete("FROM #{table} WHERE hash = '#{hash}';"))

            return [204]
        end

    end
end
