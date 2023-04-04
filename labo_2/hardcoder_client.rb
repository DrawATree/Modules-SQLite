require 'faraday'
require 'faraday/multipart'
require 'base64'


$server = Faraday.new("http://localhost:4567") do |f|
  f.request :multipart
end

def new_file(file, filepass, options, username, password)

  return puts("File not found\nStatus: 404") unless File.exists?(file)
  
  data = {
    file: Faraday::Multipart::FilePart.new(file, "text/plain"),
    file_password: filepass,
    options: options
  }

  headers = {
    "Authorization" => "Basic #{Base64.encode64("#{username}:#{password}")}"
  }

  response = $server.post("/files", data, headers) 

  puts(File.read(response.body, 16)) if response.body.start_with?("./")
  puts(response.body) unless response.body.start_with?("./")

  puts("Status: #{response.status}")
  puts("Content location: #{response.headers["Content-Location"]}") unless response.status.to_s.start_with?('40')
  aliceHash = response.headers["Content-Location"]
end

def file_creating()
  puts(' ')
  puts(' /-=-= CREATING =-=-\ ')

  filename = "jh_shawi.txt"
  filepass = "pwd"

  options = {"root" => "", "ignore" => "", "html" => "", "markdown" => ""}.to_json 
  username = "alice"
  password = "pwda" 
  new_file(filename, filepass, options, username, password)
  
  filename = 'ms_shawi.txt'
  options = {"root" => "", "ignore" => "", "html" => "", "markdown" => "yes"}.to_json 
  username = "bob"
  password = "pwdb"
  new_file(filename, filepass, options, username, password)
  
  options = {"root" => "", "ignore" => "", "html" => "yes", "markdown" => ""}.to_json 
  username = "charlie"
  password = "pwdc"
  new_file(filename, filepass, options, username, password)
  
  options = {"root" => "", "ignore" => "footer", "html" => "", "markdown" => ""}.to_json 
  username = "david"
  password = "pwdd"
  new_file(filename, filepass, options, username, password)
  
  # ----Routes alternatives
  puts("\n--Alternatives routes")
  
  #-- File not found
  puts("\n--Not found")

  filename = "notfound.txt"
  filepass = ""
  options = {"root" => "", "ignore" => "", "html" => "", "markdown" => ""}.to_json 
  username = "alice"
  password = "pwda"
  new_file(filename, filepass, options, username, password)
  
  
  #-- Not authenticate
  puts("\n--Not authenticate")

  filename = "ms_shawi.txt"
  filepass = ""
  options = {"root" => "", "ignore" => "", "html" => "", "markdown" => ""}.to_json 
  username = "unauth"
  password = "notapass"
  new_file(filename, filepass, options, username, password)
  
  ##-- file's empty
  puts("\n--File empty")

  filename = "empty.txt"
  filepass = ""
  options = {"root" => "", "ignore" => "", "html" => "", "markdown" => ""}.to_json 
  username = "alice"
  password = "pwda"
  new_file(filename, filepass, options, username, password)
end
file_creating

def update_file(hash, filepass, username, userpass)

  headers = {
    "Authorization" => "Basic #{Base64.encode64("#{username}:#{userpass}")}"
  }
  
  response = $server.patch("/files/#{hash}", filepass, headers) 
  
  puts(response.body)
  puts("Status: #{response.status}\n")
end

def file_updating()
  puts(' ')
  puts(' /-=-= UPDATING =-=-\ ')

  hash = 'oOS8sCuG'
  username = "alice"     
  userpass = "pwda"       
  newfilepass = "pwd" 

  update_file(hash, newfilepass, username, userpass)

  #--- Alternatives routes
  puts "\n--Alternatives routes"

  # Not found
  hash = 'NotFound'

  puts("\n--Not found")
  update_file(hash, newfilepass, username, userpass)

  #  Not the owner
  hash = 'oOS8sCuG'
  username = "bob"     
  userpass = "pwdb"       
  newfilepass = "pwd" 

  puts("\n--Not owner")
  update_file(hash, newfilepass, username, userpass)

  # Not authenticate
  username = ' '

  puts("\n--Not authenticate")
  update_file(hash, newfilepass, username, userpass)

end
file_updating

def delete_file(hash, username, userpass)

  headers = {
    "Authorization" => "Basic #{Base64.encode64("#{username}:#{userpass}")}"
  }
  
  response = $server.delete("/files/#{hash}",nil, headers) 

  puts(response.status)
  puts(response.body)
end

def file_deleting()
  puts(' ')
  puts(' /-=-= DELETING =-=-\ ')

  hash = 'oOS8sCuG'
  username = "alice"     
  userpass = "pwda"

  delete_file(hash, username, userpass)

  #-- Alternatives routes

  # Not Found
  puts("\n--Not found")
  delete_file(hash, username, userpass)

  # Not owner
  hash = 'sWyLXMQk'
  
  puts("\n--Not owner")
  delete_file(hash, username, userpass)

  # Not authenticate
  username = ' '
  
  puts("\n--Not authenticate")
  delete_file(hash, username, userpass)
end
file_deleting