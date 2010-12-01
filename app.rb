# coding: utf-8
require 'sinatra'
require 'slim'
require 'sass'

#Slim::Engine.set_default_options :sections => true
Slim::Engine.set_default_options :pretty => true
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
end

get '/' do
  #@insns = Insns
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

__END__

@@ index

div.caution
  | warning: These are not public API; may changed in future Ruby versions.

div#index
  | index: 

  - Insns.each do |i|
    a href="##{i.name}" = i.name
    = " " 

- Insns.each.with_index do |i, idx|
  div.insn
    a name="#{i.name}"
    h3 = i.name

    table width="100%"
      tr
        td.left width="50%"
          code
            - unless i.pops.empty?
              span.pop
                = vars(i.pops)
              = " -> "

            span.signature
              b = "#{i.name}"
              | (
              = vars(i.opes)
              | )

            - unless i.rets.empty?
              = " -> "
              span.ret
                = vars(i.rets)

          div.description
            = i.comm[:e]
            = i.comm[:j].encode("utf-8")

          - if i.sp_inc
            div.sp_inc
              | increments SP by:
              code = i.sp_inc

        td.rigth
          - if i.body.length <= CODE_CHARS_LIMIT
            pre.ccode
              = i.body
          - else
              pre.ccode0 id="ccode_#{idx}"
                = i.body[0, 100] + "..."
              pre.ccode1 id="ccode_#{idx}_all" style="display: none;"
                = i.body

javascript:
  $(".ccode0").click(function(e){
    var id = e.target.id;
    $("#"+id).toggle();
    $("#"+id+"_all").toggle();
  });
  $(".ccode1").click(function(e){
    var id = e.target.id.replace(/_all/, "");
    $("#"+id).toggle();
    $("#"+id+"_all").toggle();
  });

@@ layout
! doctype html
html
head
  meta charset="utf-8"
  title YARV instructions
  link rel="stylesheet" href="/screen.css" type="text/css"
  script src="jquery-1.4.4.js" type="text/javascript"
body
  h1 YARV instructions

  ul#menu
    li 
      a href="/" top
    li 
      a href="/about" about
    li 
      a href="/notes" notes

  == yield

  div#footer
    div#versions
      = "powered by Ruby #{RUBY_VERSION}"
    div#link
      | source: 
      a href="https://github.com/yhara/yarvinstructions" github
    div#contact
      | yhara (Yutaka Hara) 
      a href="http://route477.net" http://route477.net

@@ stylesheet
body
  // margin-left: 20%
#footer
  font-size: small
  text-align: center

@@ notes
h2 Summary of template/yarvarch.ja

markdown:
  * RubyVM of CRuby 1.9.x (formerly known as YARV) 
    - Compiler (tree of RNode -> instruction sequence)
    - an instruciton is 1 word size (= size of VALUE). not "bytecode"
    - VM instructions are defined in insns.def (compiled into \*.c/\*.h by tool/insns2vm.rb)

  * each Thread has a stack (allocated from heap).

  * RubyVM has five registers:
    - PC (Program Counter) denotes the position of the instruction being executed
    - SP (Stack Pointer) denotes stack top
    - CFP (Control Frame Pointer) 
    - LFP (Local Frame Pointer)
    - DFP (Dynamic Frame Pointer)

  * Mehtod call
    - C methods: calling the C function (with some informatino for backtraces)
    - Ruby methods: execute the compiled iseq (Instruction SEQuence)

  * Exceptions
    - look up the exception table of the current frame (like JVM.)
    - if there is an entry whose PC is the position where the exception is raised, follow the entry
    - otherwise, pop(?) the stack and look up the excepiton table of the next fram
    - (break, return in blocks, and retry are implemented in the same way)
      - compiled into the `throw' instruction

    * An exception table contains:
      - range of the target PC's
      - type of the exception
      - where to jump
      - block to invoke (compiled into iseq)

    * A rescue is transformed into an ruby block. eg(pseudo code).
          begin            {|err|
          rescue A           case err
          rescue B           when A === err
          rescue C   ==>     when B === err
          end                when C === err
                             else
                               raise # throw in iseq
                             end                       
                           }                                  

     * An ensure is compiled into two iseq's:
       - the case when no exceptions are raised
       - the case when an exception is raised (transformed into a block)
       - both end with the `throw' instruction.

  * Constant lookup
    - constants are not constant in Ruby (you know). they can be redefined
    - so constant lookup is dynamic
    - eg. (expr)::Foo::Bar::Baz is compiled to:
          (expr)
          getconstant Foo
          getconstant Bar
          getconstant Baz
      
    * Path of constant lookup
      - 1: go up the lexical nesting of classes and modules
        - klass_nest_stack of thread_object has this information(?)
      - 2: go up the ancestors to BasicObject

  * Optimization
    - Many optimization technichs are speeding up RubyVM.

    - Direct threaded code (with GCC C extension)
    - Peephole optimization
    - Inline method cache
      - inline the result of method lookup
    - Inline constant cache
      - inline the result of constant lookup
    - Lazy creation of Proc objects
      - blocks are not translated to Proc objects until they are needed
    - Specialized instructions
      - such like addition of fixnums
    - Unification of instructions
      - combine successive instructions to one instruction
      - eg. putobject+putobject, putobject+putstring, etc.
      - defined in defs/opt_insn_unif.def
    - Unification of operands
      - defined in defs/opt_operand.def
    - Stack caching
      - cache the stack top in vertual registers

    - FYI: you can select these optimizations by:
          RubyVM::InstructionSequence.compile_option = {
            :inline_const_cache       =>false,
            :peephole_optimization    =>true,
            :tailcall_optimization    =>false,
            :specialized_instruction  =>false,
            :operands_unification     =>false,
            :instructions_unification =>false,
            :stack_caching            =>false,
            :trace_instruction        =>false,
          }

          p RubyVM::InstructionSequence.compile(
            "p 1+2",       # soruce
            nil,           # file
            nil,           # path
            1,             # line
          ).to_a

          # RubyVM is a secret(undocumented) built-in class of Ruby 1.9 :-)
          # These API may change in future Ruby versions.
          # in Ruby >= 1.9.3, InstructionSequence.compile accepts options as its fifth argument.

@@ about

div
  | This site provides the list of instructions of the Ruby 1.9 VM,
  | formerly known as "YARV".
