# coding: utf-8
require 'sinatra'
require 'slim'
require 'sass'

#Slim::Engine.set_default_options :sections => true
configure :development do
#  Slim::Engine.set_default_options :pretty => true
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
  include Rack::Utils
  alias_method :h, :escape_html

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

helpers do
  def highlight_insn(html)
    html.gsub(/#{Insns.map{|i| ":#{i.name}"}.join("|")}/){|match|
      name = match.sub(/:/, "")
      "<a href='/##{h name}'>:#{h name}</a>"
    }
  end

  def highlight_opt_insn(html)
    html.gsub(/:opt_\w+/){|match|
      "<span class='opt_insn'>#{h match}</span>"
    }
  end

  def highlight_insn_in_disasm(html)
    html.gsub(/#{Insns.map{|i| "\\d+ #{i.name}"}.join("|")}/){|match|
      match =~ /(\d+) (.*)/
      addr, name = $1, $2
      if name =~ /\Aopt_/
        "#{h addr} <a href='/##{h name}' class='opt_insn'>#{h name}</a>"
      else
        "#{h addr} <a href='/##{h name}'>#{h name}</a>"
      end
    }
  end

  def prettify_disasm(disasm)
    highlight_insn disasm.gsub(/^== disasm/, "\n== disasm")
  end

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
    if optimize
      iseq = RubyVM::InstructionSequence.compile(src)
    else
      opt = Hash[*OPTIMIZATIONS.map{|n| [n, false]}.flatten]
      with_compile_opt(opt) do
        iseq = RubyVM::InstructionSequence.compile(src)
      end
    end

    html = h iseq.to_a.pretty_inspect
    tree = highlight_opt_insn highlight_insn highlight_opt_insn html

    asm = highlight_insn_in_disasm prettify_disasm iseq.disasm

    [tree, asm]
  end

  def with_compile_opt(opt)
    orig_opt= RubyVM::InstructionSequence.compile_option
    RubyVM::InstructionSequence.compile_option = opt
    yield
  ensure
    RubyVM::InstructionSequence.compile_option = orig_opt
  end
end

require 'pp'
post '/compile' do
  @src = params[:src]
  if @src.length > 10000
    @src = "source code too long X-|"
  else
    @optimized = compile(@src, true)
    @not_optimized = compile(@src, false)
  end
  slim :compile
end
__END__
