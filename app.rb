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

    db= SQLite3::Database.new('db/todo2021.db')
    db.results_as_hash = true
    result = nil
    result = db.execute("SELECT * FROM users WHERE username = ?",username).first

    if result == nil

      if password == password_confirm
        password_digest = BCrypt::Password.create(password)
        db= SQLite3::Database.new('db/todo2021.db')
        db.results_as_hash = true
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

    session[:familj_namn] = nil
    session[:startsida_text_familj] = nil
    session[:familj_id] = nil
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new('db/todo2021.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username = ?",username).first
    if result != nil
        
      pwdigest = result["pwdigest"]
      id = result["id"]

      if BCrypt::Password.new(pwdigest) == password

        session[:id_username] = id
        session[:username] = username
  
        redirect('/startsida')
      else
        "Fel lösen"
      end
  
    else
  
      "Finns ingen användare med detta namn"
  
    end
  
end

post('/familj_new') do

  #om familjen redan finns

  familj_namn = params[:family_name]
  password = params[:password]
  password_confirm = params[:password_confirm]

    db= SQLite3::Database.new('db/todo2021.db')
    db.results_as_hash = true
    result = nil
    result = db.execute("SELECT * FROM familj WHERE familj_namn = ?",familj_namn).first

    if result == nil

      if password == password_confirm
        #lägg till användare
        password_digest = BCrypt::Password.create(password)
        db= SQLite3::Database.new('db/todo2021.db')
        db.execute("INSERT INTO familj (familj_namn,pwdigest) VALUES (?,?)",[familj_namn,password_digest])
      redirect('/start_inlogg')

      else
        p "Lösenorden matchade inte"
      end

    else

      p "Familjenamnet finns redan"

    end
end

post('/login_familj') do 

  #om familjen inte finns

  familj_namn = params[:family_name]
  password = params[:password]
  db = SQLite3::Database.new('db/todo2021.db')
  db.results_as_hash = true

  result = db.execute("SELECT * FROM familj WHERE familj_namn = ?",[familj_namn]).first

  if result != nil
        
    pwdigest = result["pwdigest"]
    id = result["id"]

    if BCrypt::Password.new(pwdigest) == password

      session[:familj_id] = id
      session[:familj_namn] = familj_namn
      session[:startsida_text_familj] = "i familj #{familj_namn}"
  
      db.results_as_hash = true
      result = db.execute("SELECT * FROM familj WHERE familj_namn = ?",familj_namn).first
      id = result["id"]
      id2 = session[:id_username]
      username = session[:username]
  
      result = db.execute("SELECT * FROM familj_users WHERE user_id = ?",id2).first
      if result == nil
        db.execute("INSERT INTO familj_users (namn,admin_normal,user_id,familj_id) VALUES (?,?,?,?)",[username,0,id2, id])
      end
  
      redirect('/startsida')
    else
      "Fel lösen"
    end

  else

    p "Finns ingen familj med detta familjenamn"

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
  if user_id == nil
        
    "Inte inloggad"

  else

    db = SQLite3::Database.new("db/todo2021.db")
    db.execute("INSERT INTO todos (lista, user_id) Values (?,?)",[title, user_id])
    redirect('/inkopslista')

  end
 
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

  
  id = session[:familj_id]
  db = SQLite3::Database.new('db/todo2021.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM familj_users WHERE familj_id = ?",id)
  slim(:"familj/familj",locals:{familj_users:result})

end

post('/familj/go') do

  redirect('/familj')
end