module InsnsHelper
  def highlighted_in
  end

  def highlighted_out
  end

  def highlight_vars(insn, txt)
    invars = insn.pops.map &:last
    operands = insn.opes.map &:last
    outvars = insn.rets.map &:last

    txt = h txt
    {
      invars => "invar",
      operands => "operand",
      outvars => "outvar",
    }.each do |names, css|
      names.each do |v|
        next if v == "..."
        txt.gsub!(/\b#{v}\b/){ "<span class='#{css}'>#{v}</span>" }
      end
    end

    txt
  end
end
