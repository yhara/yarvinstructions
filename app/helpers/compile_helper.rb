module CompileHelper
  def tree(iseq)
    if iseq
      highlight_opt_insn highlight_insn h(iseq.to_a.pretty_inspect)
    else
      "compile error"
    end
  end

  def disasm(iseq)
    if iseq
      highlight_insn_in_disasm prettify_disasm iseq.disasm
    end
  end

  private

  def highlight_insn(html)
    html.gsub(/#{@insns.map{|i| ":#{i.name}"}.join("|")}/){|match|
      name = match.sub(/:/, "")
      link_to ":#{name}", insn_path(name)
    }
  end

  def highlight_opt_insn(html)
    html.gsub(/:opt_\w+/){|match|
      "<span class='opt_insn'>#{h match}</span>"
    }
  end

  def highlight_insn_in_disasm(html)
    html.gsub(/#{@insns.map{|i| "\\d+ #{i.name}"}.join("|")}/){|match|
      match =~ /(\d+) (.*)/
      addr, name = $1, $2
      if name =~ /\Aopt_/
        "#{h addr} " + link_to(name, insn_path(name), :class => "opt_insn")
      else
        "#{h addr} " + link_to(name, insn_path(name))
      end
    }
  end

  def prettify_disasm(disasm)
    highlight_insn disasm.gsub(/^== disasm/, "\n== disasm")
  end

end
