class InsnsController < ApplicationController

  def index
    @insns = Insns
  end

  def show
    name = params[:id]
    @insn = Insns.find{|i| i.name == name}
  end

end
