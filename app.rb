# coding: utf-8
require 'sinatra'
require 'slim'
require 'sass'

#Slim::Engine.set_default_options :sections => true
configure :development do
  Slim::Engine.set_default_options :pretty => true
end

module Sinatra
  module Templates
    def slim(template, options={}, locals={})
      render :slim, template, options, locals
    end 
  end
end

require './instruction.rb'
Encoding.default_external = "sjis"
Insns = RubyVM::InstructionsLoader.new.to_a

CODE_CHARS_LIMIT = 100

helpers do
  def vars(ary)
    ary.map{|v| v.join(" ")}.join(", ")
  end

  def lang_ja
    case params[:lang]
    when "ja" then true
    when "en" then false
    else request.env["HTTP_ACCEPT_LANGUAGE"] =~ /\Aja/
    end
  end
end

get '/' do
  slim :index
end

get '/screen.css' do
  sass :stylesheet
end

get '/about' do
  slim :about
end

get '/notes' do
  slim :notes
end
