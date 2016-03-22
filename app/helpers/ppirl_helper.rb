require 'set'
module PpirlHelper
  

def find_duplicates(elements)
    encountered = {}
	arr = []
    # Examine all elements in the array.
    elements.each do |e|
	# If the element is in the hash, it is a duplicate.
	if encountered[e]
	    arr << e
	else
	    # Record that the element was encountered.
	    encountered[e] = 1
	end
    end
	return arr
end

def automatic_linkage (file_paths)
  $first_line = File.foreach(file_paths[0]).first
  $column_names = $first_line.strip.split(',')
  $num_cols = $column_names.size
  
  block_var1 = "reg_num"
  block_var2 = "fname"
  link_var = Array[block_var1, block_var2, "lname", "dob"]
  matched = Set.new
  unmatched = Set.new
  uncertain = Set.new
  #$value = Hash.new{|h, k| h[k] = []}
  block_hash1 = Hash.new{|h, k| h[k] = []} # hash for storing the tuples which have block var1
  block_hash2 = Hash.new{|h, k| h[k] = []} # hash for storing the tuples which have block va2r
  tuple_count = Hash.new(0)				   # hash for counting the number of duplicate tuples
  tuple_table = Hash.new{|h, k| h[k] = []} # hash for counting the tables in which this tuple exists
  graph = Hash.new{|h, k| h[k] = []}	   # adjacency list for graph to run DFS (connected components)
  
  first_line = File.foreach(file_paths[0]).first
  col_names = first_line.strip.split(',')
  col_num = col_names.size
  puts "col_num= #{col_num}\n"
  block_index1 = col_names.index(block_var1) - 1 # index of block var 1 in table
  block_index2 = col_names.index(block_var2) - 1 # index of block var 2 in table

 
  for i in 0..file_paths.size-1 # loop through array of input files
	File.foreach(file_paths[i]).drop(1).each_slice(1) do |line|
#    File.foreach(file_paths[i]) do |line|
	  puts "line[0]= #{line[0]}\n"
      tuple = line[0].strip.split(",")
	  tuple.slice!(0)
	  puts "tuple[0]= #{tuple[0]}\n"
	  puts "tuple[1]= #{tuple[1]}\n"
	  puts "tuple[2]= #{tuple[2]}\n"
	  puts "tuple[3] #{tuple[3]}\n"
	  puts "tuple[4]= #{tuple[4]}\n"
	  puts "tuple[5]= #{tuple[5]}\n"
      block_hash1[tuple[block_index1]] << tuple 
      block_hash2[tuple[block_index2]] << tuple  
	  tuple_count[tuple] += 1
	  if !(tuple_table[tuple].include? i+1) 
	    tuple_table[tuple] << i+1 
	  end
    end
  end
  
  block_hash1.keys.each do |key|
    puts "#{key}-----"
	puts "block_hash1[key].size= #{block_hash1[key].size}\n"
	if block_hash1[key].size == 1 # this id has no matching row, its single
      unmatched << block_hash1[key]		
	  next
	end

	# remove duplicate elements
	dup = find_duplicates(block_hash1[key])
	block_hash1[key].uniq!
	dup.each do |v|
		if block_hash1[key].include? v
			block_hash1[key].delete(v)
		end
	end
	puts "block_hash1[key].size= #{block_hash1[key].size}\n"
	#puts "block_hash1[key]= #{block_hash1[key]}\n"

    for i in 0..block_hash1[key].size-2
	  for j in 1..block_hash1[key].size-1
		flag = 0
        for k in 0..col_num-2
          if block_hash1[key][i][k] != block_hash1[key][j][k]
            flag = 1
            break
          end
        end
        if flag == 0
          matched << block_hash1[key][i]
        else
          uncertain << block_hash1[key][i]  
          uncertain << block_hash1[key][j] 
		  graph[block_hash1[key][i]] << block_hash1[key][j]
		  graph[block_hash1[key][j]] << block_hash1[key][i]
		end
	  end 
    end
	
  end
  
  block_hash2.keys.each do |key|
    puts "#{key}-----"
	puts "block_hash2[key].size= #{block_hash2[key].size}\n"
	
	if block_hash2[key].size == 1 # this id has no matching row, its single
      unmatched << block_hash2[key]  
	  next
	end
	
	dup = find_duplicates(block_hash2[key])
	#puts "DUPLICATE= #{dup}\n"
	#puts "DUPLICATESIZE= #{dup.size}\n"
	block_hash2[key].uniq!
	dup.each do |v|
		if block_hash2[key].include? v
			block_hash2[key].delete(v)
		end
	end
	puts "block_hash2[key].size= #{block_hash2[key].size}\n"
	#puts "block_hash2[key]= #{block_hash2[key]}\n"
 
   for i in 0..block_hash2[key].size-2
		puts "i = #{i}\n"
	  if unmatched.include? block_hash2[key][i]
        unmatched.delete? block_hash2[key][i]
	  end
	  for j in i+1..block_hash2[key].size-1
		puts "j = #{j}\n"
		flag = 0
        for k in 0..col_num-2
          if block_hash2[key][i][k] != block_hash2[key][j][k]
            flag = 1
            break
          end
        end
        if flag == 0
          matched << block_hash2[key][i]  
        else
          uncertain << block_hash2[key][i]  
          uncertain << block_hash2[key][j] 
		  puts "block_hash2[key][i]= #{block_hash2[key][i]}\n"
		  puts "block_hash2[key][j]= #{block_hash2[key][j]}\n"
		  graph[block_hash2[key][i]] << block_hash2[key][j]
		  graph[block_hash2[key][j]] << block_hash2[key][i]
		  
		  if unmatched.include? block_hash2[key][j]
            unmatched.delete? block_hash1[key][j]
		  end
		end
	  end 
    end
	
  end

  puts "graph - adjacency list\n"
  graph.each do |key, value|
	puts "key = #{key}"
	puts "value = #{value}\n"
  end
=begin
  puts "matched\n"
  matched.each do |val|
    puts "value = #{val}\n"
  end
  puts "unmatched\n"
  unmatched.each do |val|
    puts "value = #{val}\n"
  end
  puts "uncertain\n"
  uncertain.each do |val|
    puts "value = #{val}\n"
  end
=end

	#DFS on graph

	color = Hash.new{|h, k| h[k] = []} # hash for storing the color status of node
	cluster = Hash.new{|h, k| h[k] = []} # hash for storing the connected components/clusters
	graph.each do |key, value|
		color[key] = 'W';	
	end
	label = 0
	graph.each do |key, value|
		if(color[key] == 'W') 
			label = label + 1
			DFS(key, label, color, cluster, graph)
		end
	end
	
	puts "CLUSTER\n"
	cluster.each do |key, value|
		puts "key = #{key}"
		puts "value = #{value}\n"
		value.each do |val|
			puts "val = #{val}\n"
			val.each do |v|
				puts "v = #{v}\n"
			end
		end
			
	end
	
	return cluster

end

def DFS(node, label, color, cluster, graph)
	color[node] = 'G'
	cluster[label] << node
	graph[node].each do |v|
		if color[v] == 'W'
			DFS(v, label, color, cluster, graph)
		end
	end
	color[node] = 'B'
end


#file_paths = Array["/home/guest/Desktop/DirectedStudies/test-automatic1.csv","/home/guest/Desktop/DirectedStudies/test-automatic2.csv"]
#file_paths = Array["/home/guest/Desktop/DirectedStudies/db0709-small.csv","/home/guest/Desktop/DirectedStudies/db0829-small.csv"]
#automatic_linkage(file_paths)

  
  
  
  def get_edit_distance(s1, s2)
    finalStr1 = ""
    finalStr2 = ""
    
    if ((s1.blank?) && (s2.blank?))
      return finalStr1, finalStr2
    end
    
    if(s1.blank?)
        return finalStr1, s2
    end
    if(s2.blank?)
        return s1, finalStr2
    end
    
    
    
    len1 = s1.length
    len2 = s2.length
    

    dp = Hash.new{|h, k| h[k] = []}
    direction = Hash.new{|h, k| h[k] = []}

    for i in 0..len1
      for j in 0..len2
        if i == 0
          dp[i][j] = j
          direction[i][j] = 'd'
        elsif j == 0
          dp[i][j] = i
          direction[i][j] = 'i'
        elsif s1[i - 1] == s2[j - 1]
          dp[i][j] = dp[i - 1][j - 1]
          direction[i][j] = 'n'
        else
          insertVal = dp[i - 1][j]
          deleteVal = dp[i][j - 1]
          subsVal = dp[i - 1][j - 1]

          transVal = 1000000000
          if i > 1 and j > 1 and s1[i - 1] == s2[j - 2] and s1[i - 2] == s2[j - 1]
            transVal = dp[i - 2][j - 2]
          end

          minAll = [insertVal, deleteVal, subsVal, transVal].min

          if minAll == transVal
              direction[i][j] = 't'
          elsif minAll == insertVal
              direction[i][j] = 'i'
          elsif minAll == deleteVal
              direction[i][j] = 'd'
          else
              direction[i][j] = 's'
          end
          dp[i][j] = minAll + 1
        end
      end
    end

    
    stI = len1
    stJ = len2
    while stI > 0 or stJ > 0
      if direction[stI][stJ] == 'i'
        finalStr1 = s1[stI - 1] + finalStr1
        finalStr2 = " " + finalStr2
        stI = stI - 1

      elsif direction[stI][stJ] == 'd'
        finalStr1 = " " + finalStr1
        finalStr2 = s2[stJ -1] + finalStr2
        stJ = stJ - 1

      elsif direction[stI][stJ] == 's'
        finalStr1 = s1[stI -1] + finalStr1
        finalStr2 = s2[stJ - 1] + finalStr2
        stI = stI - 1
        stJ = stJ - 1

      elsif direction[stI][stJ] == 'n'
        finalStr1 = "-" + finalStr1
        finalStr2 = "-" + finalStr2
        stI = stI - 1
        stJ = stJ - 1

      else
        finalStr1 = "TX" + finalStr1
        finalStr2 = "TX" + finalStr2
        stI = stI - 2
        stJ = stJ - 2
      end
    end

    puts finalStr1, finalStr2

    return finalStr1, finalStr2
  end

  # This is a private fucntion. Not for public use.
  # Returns
  # true if any key in the hash is a subset of the set provided.
  # false otherwise.
  def contains(hash, set)
    hash.each do |this_set, cnt|
      if this_set.subset? set
        return true
      end
    end
    return false
  end

  def apriori_algorithm(cluster, threshold)
    ans = Hash.new
    threshold = threshold.to_i
    # This creates the set of size 1
    hash = Hash.new
    hash.default = 0
    
    cluster.each do |key, value|
       if value.size >= 2
            for i in 0..1
              if i == 0
                  values_one = value[i]
              else
                  values_two = value[i]
              end
            end
    
            #File.foreach(file_path).drop(1).each_slice(2) do |line|
            #  values_one = line[0].strip.split(',')
            #  values_two = line[1].strip.split(',')
            for col in 0..values_one.size - 1
              if(!values_one[col].blank?)
                s1 = Set.new [values_one[col].clone]
              end
              if(!values_two[col].blank?)
                s2 = Set.new [values_two[col].clone]
              end
              hash[s1] += 1
              hash[s2] += 1
            end
        end
    end


    cnt = 2
    # On each iteration of this loop, sets of size one larger than the previous size is considered.
    while hash.size > 0

      # Debugging nuisance.
      puts "Count ", cnt
      puts "Hash", hash

      new_hash = Hash.new
      new_hash.default = 0
      # Put all the items less than the threshold in the ans hash.
      hash.each do |set, count|
        if count < threshold
          ans[set.clone] = count
        end
      end

      # This loop for all the items with size greater than threshold.
      hash.each do |set, count|
        if count >= threshold
          # For each set, look at all the rows it may be a subset of to create new candidates. For this, we are looking
          # at the whole file row by row.
          
          cluster.each do |key, value|
            if value.size >= 2
              for i in 0..1
                if i == 0
                    values_one = value[i].to_set
                else
                    values_two = value[i].to_set
                end
              end
          
          #File.foreach(file_path).drop(1).each_slice(2) do |line|
            #values_one = line[0].strip.split(',').to_set
            # If this set is subset of the row, we have to process to create new candidates.
            if set.subset? values_one
              # We will look at all the values that can be added to the set to form a new candidate.
              values_one.each do |value|
                # Don't consider if the value is already a part of the set.
                if !set.include? value
                  temp_set = set.clone
                  temp_set.add(value)
                  # If any set in the answer is a subset of the new set created here, we don't need to consider the new
                  # set.
                  if !contains(ans, temp_set)
                    new_hash[temp_set.clone] += 1
                  end
                end
              end
            end

            # Do everything again for the second row.
            #values_two = line[1].strip.split(',').to_set
            if set.subset? values_two
              values_two.each do |value|
                if !set.include? value
                  temp_set = set.clone
                  temp_set.add(value)
                  if !contains(ans, temp_set)
                    new_hash[temp_set.clone] += 1
                  end
                end
              end
            end
           end
          end
        end
      end
      # Since each set of size k will be from a set of size k - 1 in k ways, we are dividing by k to get the actual
      # count.
      new_hash.each do |set, count|
        new_hash[set] = count/cnt
      end

      # Debugging nuisance.
      puts "New hash ", new_hash
      puts "ans ", ans
      puts ""

      hash = new_hash.clone
      cnt += 1
    end

    return ans
  end
end

=begin
def automatic_linkage (file_paths)
  block_var = "reg_num"
  #link_var = Array[bloack_var, "fname", "lname", "dob"]
  $matched = Hash.new{|h, k| h[k] = []}
  $unmatched = Hash.new{|h, k| h[k] = []}
  $uncertain = Hash.new{|h, k| h[k] = []}
  $value = Hash.new{|h, k| h[k] = []}
  $id_hash = Hash.new{|h, k| h[k] = []}
  
  first_line = File.foreach(file_paths[0]).first
  col_names = first_line.strip.split(',')
  col_num = col_names.size
  id_index = $col_names.index(block_var) # primary key like reg_num
   
  for i in 0..$file_paths.size # loop through array of input files
    File.foreach(file_paths[i]).drop(1) do |line|
      value = line.strip.split(',')
      id_hash[value[id_index]] += value  
    end
  end
  
  id_hash.keys.each do |key|
    puts "#{key}-----"
    if id_hash[key].size == 2 # at least id is same
      flag = 0
      for i in 0..col_num
        if id_hash[key][0][i] != id_hash[key][1][i]
          flag = 1
          break
        end
      end
      if flag == 0
        $matched[key] += id_hash[key]  
      else
        $uncertain[key] += id_hash[key]  
      end
    else # this id has no matching row, its single
      $unmatched[key] += id_hash[key]  
    end
  end

  
end
=end

# Testing code. TODO To be removed later.
#include PpirlHelper
#threshold = 3
#file_path = "/home/ubuntu/workspace/test-full.csv"
#puts apriori_algorithm(@filepath, threshold)
# # Example 1
# s1 = "Dr. John Naash"
# s2 = "John Naesh Sr."
# puts s1
# puts s2
# finalStr1, finalStr2 = get_edit_distance(s1, s2)
# puts finalStr1
# puts finalStr2
# puts ""
#
# # Example 2
# s1 = "sachin"
# s2 = "sachni"
# puts s1
# puts s2
# finalStr1, finalStr2 = get_edit_distance(s1, s2)
# puts finalStr1
# puts finalStr2
# puts ""
#
# # Example 3
# s1 = "andrew"
# s2 = "anrdes"
# puts s1
# puts s2
# finalStr1, finalStr2 = get_edit_distance(s1, s2)
# puts finalStr1
# puts finalStr2
# puts ""
#
# # Example 4
# s1 = "Sam"
# s2 = "Samantha"
# puts s1
# puts s2
# finalStr1, finalStr2 = get_edit_distance(s1, s2)
# puts finalStr1
# puts finalStr2
# puts ""
#
#
# # Example 5
# s1 = "Samantha"
# s2 = "Coxiantha"
# puts s1
# puts s2
# finalStr1, finalStr2 = get_edit_distance(s1, s2)
# puts finalStr1
# puts finalStr2
# puts ""