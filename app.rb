require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
enable :sessions

get('/startsida') do

  slim(:start)

end

get('/start_inlogg') do

  slim(:start_inlogg)

end

post('/users_new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]

    bob = 3
    if bob == 3

      if password == password_confirm
        #lägg till användare
        password_digest = BCrypt::Password.create(password)
        db= SQLite3::Database.new('db/todo2021.db')
        db.execute("INSERT INTO users (username,pwdigest) VALUES (?,?)",[username,password_digest])
        redirect('/start_inlogg')
    
      else
        p "Lösenorden matchade inte"
      end

    else
      
        p "Användarnamnet finns redan"

    end
end

post('/login_user') do 

  #om använderen inte finns


    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new('db/todo2021.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username = ?",username).first
    pwdigest = result["pwdigest"]
    id = result["id"]
  
    if BCrypt::Password.new(pwdigest) == password

      session[:id_username] = id
      session[:username] = username

      redirect('/startsida')
    else
      "Fel lösen"
    end
end

post('/familj_new') do

  #om familjen redan finns

  familj_namn = params[:family_name]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if password == password_confirm
    #lägg till användare
    password_digest = BCrypt::Password.create(password)
    db= SQLite3::Database.new('db/todo2021.db')
    db.execute("INSERT INTO familj (familj_namn,pwdigest) VALUES (?,?)",[familj_namn,password_digest])
    redirect('/start_inlogg')

  else
    p "Lösenorden matchade inte"
  end
end

post('/login_familj') do 

    #om familjen inte finns

  familj_namn = params[:family_name]
  password = params[:password]
  db = SQLite3::Database.new('db/todo2021.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM familj WHERE familj_namn = ?",familj_namn).first
  pwdigest = result["pwdigest"]
  id = result["id"]

  if BCrypt::Password.new(pwdigest) == password

    session[:familj_id] = id
    session[:familj_namn] = familj_namn
    session[:startsida_text_familj] = "i familj #{familj_namn}"

    redirect('/startsida')
  else
    "Fel lösen"
  end
end

post('/utlogg') {

  
  session[:username] = nil
  session[:id_username] = nil
  session[:familj_namn] = nil
  session[:startsida_text_familj] = nil
  session[:familj_id] = nil

  redirect('/startsida')

}

#listor

get('/inkopslista') do

  id = session[:id_username]
  db = SQLite3::Database.new('db/todo2021.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM todos WHERE user_id = ?",id)
  slim(:"inkop/inkopslista",locals:{todos:result})

end

post('/inkopslista/:id/delete') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/todo2021.db")
  db.execute("DELETE FROM todos WHERE todo_id = ?",id)
  redirect("/inkopslista")
end

get('/inkopslista/:id/edit') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/todo2021.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM todos WHERE todo_id = ?",id).first
  slim(:"/inkop/edit_list", locals:{result:result})
end

post('/inkopslista/:id/update') do
  id = params[:id].to_i
  lista = params[:title]
  user_id = params[:user_id].to_i
  db = SQLite3::Database.new("db/todo2021.db")
  db.execute("UPDATE todos SET lista=?,user_id=? WHERE todo_id = ?",[lista,user_id,id])
  redirect('/inkopslista')
  
end

post('/inkopslista/new') do
  title = params[:title]
  user_id = session[:id_username]
  db = SQLite3::Database.new("db/todo2021.db")
  db.execute("INSERT INTO todos (lista, user_id) Values (?,?)",[title, user_id])
  redirect('/inkopslista')
end

#inne i listorna

post('/inkopslista/:id/show/:idd/delete') do
  id = params[:id].to_i
  idd = params[:idd].to_i
  db = SQLite3::Database.new("db/todo2021.db")
  db.execute("DELETE FROM egna_listor WHERE todo_id = ?",idd)
  redirect("/inkopslista/#{id}/show")
end

get('/inkopslista/:id/show/:idd/edit') do
  id = params[:idd].to_i
  db = SQLite3::Database.new("db/todo2021.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM egna_listor WHERE todo_id = ?",id).first
  slim(:"/inkop/edit_in_list", locals:{result:result})
end


post('/inkopslista/:id/show/:idd/update') do
  id = params[:id].to_i
  idd = params[:idd].to_i
  content = params[:title]
  user_id = params[:user_id].to_i
  db = SQLite3::Database.new("db/todo2021.db")
  db.execute("UPDATE egna_listor SET content=?,id=? WHERE todo_id = ?",[content,user_id,idd])
  p id
  redirect("/inkopslista/#{id}/show")
  
end

post('/inkopslista_tillbaka') do
  redirect("/inkopslista")
end

get('/inkopslista/:id/show') do
  id = params[:id].to_i
  session[:idd] = id
  db = SQLite3::Database.new("db/todo2021.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM egna_listor WHERE id = ?",id)
  slim(:"inkop/show",locals:{egna_listor:result})
end

post('/inkopslista/:id/show/new') do
  id = params[:id].to_i
  content = params[:title]
  db = SQLite3::Database.new("db/todo2021.db")
  db.execute("INSERT INTO egna_listor (id, content) Values (?,?)",[id, content])
  redirect("/inkopslista/#{id}/show")
end

#familj sidan
get('/familj') do

  slim(:familj)

end