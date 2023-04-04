require 'faraday'
require 'faraday/multipart'
require 'base64'

$server = Faraday.new("http://localhost:4567") do |f|
    f.request :multipart
end
$username = ""
$password = ""

def header
    puts("~~~~~~~~~   LABO 2   File Gestionner   ~~~~~~~~~")
end

def clear
    system("clear")
end
  
def wait_enter
    print("\nPress Enter to continue...")
    gets
end

def login
    clear()

    print("Username: ")
    username = gets.strip
    
    print("Password: ")
    password = gets.strip

    headers = {
        "Authorization" => "Basic #{Base64.encode64("#{username}:#{password}")}"
    }

    response = $server.get("/login", nil, headers)

    if response.body.start_with?("Provide")
        puts(response.body)
        wait_enter()
        login()
    end

    $username = username
    $password = password
end

def list()
    clear()

    headers = {
        "Authorization" => "Basic #{Base64.encode64("#{$username}:#{$password}")}"
    }

    response = $server.get("/files", nil, headers)

    puts(JSON.parse(response.body))

    wait_enter()
end

def add()
    clear()
    options = {}

    puts("Enter file name.")
    print(">> ")
    filename = gets.strip

    clear()
    puts("\t-Warning- If there's multiple urls in the file, all of those will have the same parameters")
    puts("Do you want the file to have a password?\n\tIf yes, enter it.\n\tIf no, press enter.")
    print(">> ")
    filepassword = gets.strip

    clear()
    puts("\t-Warning- If there's multiple urls in the file, all of those will have the same parameters")
    puts("What do you want to root?\n\tIf none, press enter.")
    print(">> ")
    options["root"] = gets.strip

    clear()
    puts("\t-Warning- If there's multiple urls in the file, all of those will have the same parameters")
    puts("Is there some elements that you want to ignore?\n\tIf none, press enter.")
    print(">> ")
    options["ignore"] = gets.strip

    clear()
    puts("\t-Warning- If there's multiple urls in the file, all of those will have the same parameters")
    puts("Do you want the result in HTML?\n\tIf yes, type yes\n\tIf no, type no.")
    print(">> ")
    temp = gets.strip.downcase
    options["html"] = "yes" if temp == "yes"
    options["html"] = "" unless temp == "yes"

    clear()
    puts("\t-Warning- If there's multiple urls in the file, all of those will have the same parameters")
    puts("Do you want the result in MARKDOWN?\n\tIf yes, type yes\n\tIf no, type no.")
    print(">> ")
    temp = gets.strip.downcase
    options["markdown"] = "yes" if temp == "yes"
    options["markdown"] = "" unless temp == "yes"

    clear()

    data = {
        file: Faraday::Multipart::FilePart.new(filename, "text/plain"),
        file_password: filepassword,
        options: options.to_json
    }
    
    headers = {
        "Authorization" => "Basic #{Base64.encode64("#{$username}:#{$password}")}"
    }

    response = $server.post("/files", data, headers) 

    # Files won't be print on the screen, causes some problems if there's multiple urls
    puts(response.body)
  
    puts("\nContent location: #{response.headers["Content-Location"]}") unless response.status.to_s.start_with?('40')  

    wait_enter()
end

def modify()
    clear()
    
    puts("Enter the hash corresponding to the file that you want to modify the password.\n\tDon't remember? Type 'EXIT' then go to list.")
    print(">> ")
    hash = gets.strip
    return if hash == "EXIT" || hash.empty?
    
    clear()
    puts("Enter the new file password.")
    print(">> ")
    filepass = gets.strip
    
    clear()

    headers = {
        "Authorization" => "Basic #{Base64.encode64("#{$username}:#{$password}")}"
    }

    response = $server.patch("/files/#{hash}", filepass, headers) 
    
    puts(response.body)
    puts("Status: #{response.status}\n")
    
    wait_enter()
end

def delete()
    clear()
    
    puts("Enter the hash corresponding to the file that you want to delete.\n\tDon't remember? Type 'EXIT' then go to list.")
    print(">> ")
    hash = gets.strip
    return if hash == "EXIT" || hash.empty?

    clear()

    headers = {
        "Authorization" => "Basic #{Base64.encode64("#{$username}:#{$password}")}"
    }

    response = $server.delete("/files/#{hash}", nil, headers) 
    
    puts(response.body)
    puts("Status: #{response.status}\n")
    
    wait_enter()
end

def quit()
    clear()
    exit()
end

def menu_input
    clear()
    header()

    puts(" l: List  a: Add  m: Modify  d: Delete  q: Quit")
    print(">> ")
    choice = gets.strip.downcase

    clear()
    header()

    actions = {
        "l" => method(:list),
        "a" => method(:add),
        "m" => method(:modify),
        "d" => method(:delete),
        "q" => method(:quit)
    }

    actions[choice]
end

def menu
    loop do
        login()

        loop do
            action = menu_input()

            if action.nil?
                puts("Invalid choice!")
                wait_enter()
            else
                action.call()
            end
        end
    end
end
  
menu 