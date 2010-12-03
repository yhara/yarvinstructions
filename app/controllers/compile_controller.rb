require 'pp'

class CompileController < ApplicationController
  def index
    @insns = Insns
    @src = params[:src] || "1+2"

    if @src.length > 10000
      @src = "source code too long X-|"
    else
      @optimized = compile(@src, true)
      @not_optimized = compile(@src, false)
    end
  end

  private
  
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
      RubyVM::InstructionSequence.compile(src)
    else
      opt = Hash[*OPTIMIZATIONS.map{|n| [n, false]}.flatten]
      with_compile_opt(opt) do
        RubyVM::InstructionSequence.compile(src)
      end
    end
  rescue SyntaxError
    nil
  end

  def with_compile_opt(opt)
    orig_opt= RubyVM::InstructionSequence.compile_option
    RubyVM::InstructionSequence.compile_option = opt
    yield
  ensure
    RubyVM::InstructionSequence.compile_option = orig_opt
  end
end
