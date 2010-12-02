require 'pp'

class CompileController < ApplicationController
  def index
    @src = params[:src] || "1+2"

    if @src.length > 10000
      @src = "source code too long X-|"
    else
      @optimized = compile(@src, true)
      @not_optimized = compile(@src, false)
    end
  end

  private
  
  include Rack::Utils
  alias h escape_html

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

    tree + "\n" + asm
  rescue SyntaxError
    "compile error"
  end

  def with_compile_opt(opt)
    orig_opt= RubyVM::InstructionSequence.compile_option
    RubyVM::InstructionSequence.compile_option = opt
    yield
  ensure
    RubyVM::InstructionSequence.compile_option = orig_opt
  end
end
