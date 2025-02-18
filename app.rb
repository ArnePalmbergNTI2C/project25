require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
enable :sessions

get('/startsida') do

    slim(:start)

end

post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
  
    if password == password_confirm
      #lägg till användare
      password_digest = BCrypt::Password.create(password)
      db= SQLite3::Database.new('db/todo2021.db')
      db.execute("INSERT INTO users (username,pwdigest) VALUES (?,?)",[username,password_digest])
      redirect('/start_inlogg')
  
    else
      p "Lösenorden matchade inte"
    end
end

get('/start_inlogg') do

    slim(:start_inlogg)

end

post('/login') do 
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new('db/todo2021.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username = ?",username).first
    pwdigest = result["pwdigest"]
    id = result["id"]
  
    if BCrypt::Password.new(pwdigest) == password

      session[:id] = id
      session[:username] = username

      p id

      redirect('/startsida')
    else
      "Fel lösen"
    end
end



get('/inloggg') do


    id = session[:id].to_i
    p id
    db = SQLite3::Database.new('db/todo2021.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM todos WHERE user_id = ?",id)  
    slim(:"inloggg",locals:{todos:result})

end

get('/inköpslista') do

    slim(:inköpslista)

end

get('/familj') do

    slim(:familj)

end

get('/extra') do

    slim(:extra)

end