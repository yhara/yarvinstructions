class ApplicationController < ActionController::Base
  protect_from_forgery

  require_relative "#{Rails.root}/yarv/instruction.rb"
  vpath = ["#{Rails.root}/yarv"].extend(RubyVM::VPATH)
  Encoding.default_external = "sjis"
  Insns = RubyVM::InstructionsLoader.new(:VPATH => vpath).to_a
  Encoding.default_external = "utf-8"
end
