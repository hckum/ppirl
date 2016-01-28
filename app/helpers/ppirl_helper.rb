require 'set'
module PpirlHelper
  def get_edit_distance(s1, s2)
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

    finalStr1 = ""
    finalStr2 = ""
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


  def apriori_algorithm(file_path)
    threshold = 5
    ans = Hash.new

    # This creates the set of size 1
    # file_path = "/Users/ankurgupta/Desktop/job/test_data_1.txt"
    hash = Hash.new
    hash.default = 0
    File.foreach(file_path).drop(1).each_slice(2) do |line|
      values_one = line[0].strip.split(',')
      values_two = line[1].strip.split(',')
      for col in 0..values_one.size - 1
        s1 = Set.new [values_one[col].clone]
        s2 = Set.new [values_two[col].clone]
        hash[s1] += 1
        hash[s2] += 1
      end
    end

    while hash.size > 0
      new_hash = Hash.new
      new_hash.default = 0
      hash.each do |set, count|
        if count < threshold
          ans[set.clone] = count
        else
          File.foreach(file_path).drop(1).each_slice(2) do |line|
            values_one = line[0].strip.split(',').to_set
            values_two = line[1].strip.split(',').to_set
            if set.subset? values_one
              values_one.each do |value|
                if !set.include? value
                  new_hash[set.clone.add(value)] += 1
                end
              end
            end

            if set.subset? values_two
              values_two.each do |value|
                if !set.include? value
                  new_hash[set.clone.add(value)] += 1
                end
              end
            end
          end
        end
        hash = new_hash
      end
    end

    return ans
  end


end


# include PpirlHelper
# file_path = "/Users/ankurgupta/Desktop/job/test_data_1.txt"
# puts apriori_algorithm(file_path)
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

