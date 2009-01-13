module RubyAMP::PrettyAlign
  def pretty_align(input, separator_str=nil)
    input ||= ""
    
    if separator_str
      separator_obj = case
        when separator_str.is_a?(Regexp)
          instance_eval(separator_str.inspect)
        when separator_str.strip =~ /^\/(.+?)\/\w*$/
          instance_eval(separator_str)
        else
          separator_str
        end
      
      lines = []
      
      input.split(/\n/, -1).each do |line|
        if separator_obj.is_a?(Regexp) ? line =~ separator_obj : line[separator_obj]
          separator = ($& || separator_obj).strip
          left, right = line.split(separator_obj, 2)
          lines << [left.to_s.rstrip, separator, right.to_s.strip]
        else
          lines << [line]
        end
      end
      
      max_left      = lines.max {|a,b| !a[2] ? -1 : a[0].to_s.length <=> b[0].to_s.length }
      max_left      = max_left[0] if max_left
      max_separator = lines.max {|a,b| !a[1] ? -1 : a[1].to_s.length <=> b[1].to_s.length }
      max_separator = max_separator[1] if max_separator
      max_left      = max_left.length      if max_left
      max_separator = max_separator.length if max_separator
      
      output = []
      lines.each do |left, separator, right|
        if right
          output << format("%-#{max_left}s %-#{max_separator}s %s", left, separator, right)
        else
          output << left
        end
      end
      
      output.join("\n")
    else
      line_hashes = []
      max_tokens = 0
      
      input.split(/\n/, -1).each do |line|
        split_line = line.scan(/(.+?)([,!~=><\*&\|\/\-\+%]+)(.+?|$)/)
        split_line[-1][-1] << line[split_line.to_s.size..-1] unless split_line.to_s.size == line.size
        tokens     = split_line.map { |e| e[1] }
        max_tokens = tokens.size if tokens.size > max_tokens
        line_hashes << {:line => split_line, :tokens => tokens}
      end
      
      0.upto(max_tokens - 1) do |token_num|
        next if line_hashes.map { |l| l[:tokens][token_num] }.compact.uniq.size > 1
        max_left      = line_hashes.inject(0) { |max, l| l[:line][token_num] && size = l[:line][token_num][0].size; max = size if (size||0) > max; max }
        max_separator = line_hashes.inject(0) { |max, l| l[:line][token_num] && size = l[:line][token_num][1].size; max = size if (size||0) > max; max }
        line_hashes.each do |l|
          if l[:line][token_num]
            left  = l[:line][token_num][0]
            sep   = l[:line][token_num][1]
            right = l[:line][token_num][2]
          end
          if sep == ','
            l[:line][token_num] = format("%s%-#{max_left - left.size + 1}s%s", left, sep, right)
          else
            l[:line][token_num] = format("%-#{max_left}s%-#{max_separator}s%s", left, sep, right)
          end
        end
      end
      
      line_hashes.map { |l| l[:line].join.rstrip }.join("\n")
    end
  rescue Exception => e
    if testing?
      raise e 
    else
      input
    end
  end
  
  def testing?; @testing; end
  def testing=(boolean)
    @testing = boolean
  end
end