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
Encoding.default_external = "utf-8"

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

# static contents

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

# dynamic contents

get '/compile' do
  slim :compile
end
22

helpers do
  OPTIMIZATIONS = [
    :inline_const_cache       ,
    :peephole_optimization    ,
    :tailcall_optimization    ,
    :specialized_instruction  ,
    :operands_unification     ,
    :instructions_unification ,
    :stack_caching            ,
    :trace_instruction        ,
  ]
  def compile(src, optimize)
    opt = Hash[*OPTIMIZATIONS.map{|n| [n, optimize]}.flatten]
    RubyVM::InstructionSequence.compile_option = opt
    RubyVM::InstructionSequence.compile(src)
  end
end

require 'pp'
post '/compile' do
  @src = params[:src]
  if @src.length > 10000
    @src = "source code too long X-|"
  else
    @optimized = compile(@src, true).to_a.pretty_inspect
    @optimized.gsub!(/:opt_\w+/){|match|
      "<span class='opt_insn'>#{match}</span>"
    }
    @not_optimized = compile(@src, false).to_a.pretty_inspect
  end
  slim :compile
end
