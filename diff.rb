if ARGV.count != 2
  script_name = $0

  puts "#{script_name}: 2 and only 2 filenames are required as arguments"
  puts "#{script_name}: Try `ruby #{script_name} ORIGINAL MODIFIED`"

  exit
end

# helpers definitions

# safely readlines from files checking file existance
def safe_readlines(filename)
  unless File.exists?(filename)
    puts "File #{filename} not found"
    return
  end

  # assume files are not huge as their comparison makes no sense in this case
  File.readlines(filename).map{|line| line.strip}
end

# simple slow recursive LCS implementation between ORIGINAL and MODIFIED
def lcs(original, modified)
  return [] unless original.any? && modified.any?

  original_start, *original_rest = original
  modified_start, *modified_rest = modified

  return [original_start] + lcs(original_rest, modified_rest) if original_start == modified_start

  seq_a = lcs(original, modified_rest)
  seq_b = lcs(original_rest, modified)
  (seq_a.count > seq_b.count) ? seq_a : seq_b
end

# state values
def diff_state(state, original: nil, modified: nil, common: nil)
  # if NOT CHANGED - fill both
  original = modified = common if state == :not_changed

  {
      state: state,
      original: original,
      modified: modified
  }
end

def diff(original, modified, lcs = lcs(original, modified))
  res = []

  # process common sequence
  while lcs.any?
    lcs_start = lcs.shift
    modified_buffer = [] # a part of res where we merge delete and insert sates into modified

    while modified.any?
      modified_start = modified.shift
      break if modified_start == lcs_start

      modified_buffer << diff_state(:insert, modified: modified_start)
    end

    while original.any?
      original_start = original.shift
      break if original_start == lcs_start

      if available_diff = modified_buffer.find{|d| d[:state] != :modified}
        # change available diff state from insert to modified
        # important to change found object to make changes inside modified_buffer element, not its clone
        available_diff[:state] = :modified
        available_diff[:original] = original_start
      else
        modified_buffer << diff_state(:delete, original: original_start)
      end
    end

    res += modified_buffer
    res << diff_state(:not_changed, common: lcs_start)
  end

  # process tails
  modified.each{|line| res << diff_state(:insert, modified: line)}
  original.each{|line| res << diff_state(:delete, original: line)}

  res
end



def specified_puts(diff)
  count = 0

  diff.each do |line|
    print "#{count += 1}\t"

    case line[:state]
      when :modified
        puts "*\t#{line[:original]}|#{line[:modified]}"
      when :delete
        puts "-\t#{line[:original]}"
      when :insert
        puts "+\t#{line[:modified]}"
      when :not_changed
        puts " \t#{line[:original]}"
      else
        puts "!\tUNKNOWN STATE\t#{line}"
    end
  end
end


# main part

# we know there are only 2 of them
text1 = safe_readlines(ARGV[0])
text2 = safe_readlines(ARGV[1])
abort unless text1 and text2

specified_puts diff(text1.dup, text2.dup)