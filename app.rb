require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
#require 'becrypt'

get('/startsida') do

    slim(:start)


get('/inköpslista') do

    slim(:inköpslista)

end

get('/familj') do

    slim(:familj)

end

get('/extra') do

    slim(:extra)

end