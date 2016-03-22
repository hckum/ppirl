require 'set'
require 'open-uri'
class PpirlController < ApplicationController
  include PpirlHelper

  $filepath1 = ""
  $filepath2 = ""
  $threshold = ""
  #$budget = 0
  #$file_path = "/Users/ankurgupta/Desktop/job/test_data_1.txt"

  $values_first = Hash.new{|h, k| h[k] = []}
  $values_second = Hash.new{|h, k| h[k] = []}
  $values_revealed = Hash.new{|h, k| h[k] = []}
  $values_first_shown = Hash.new{|h, k| h[k] = []}
  $values_second_shown = Hash.new{|h, k| h[k] = []}
  $cluster = Hash.new{|h, k| h[k] = []} # hash for storing the connected components/$clusters
  $is_match = Array.new

  $num_rows = 0
  $num_cols = 0
  $column_names = Array.new
  $first_line

  $start_index = 0
  $gap = 5

  #$threshold = 3
  $all_rare_sets = Hash.new
  $privacy_budget = 100.0


  def index
    #@dbases = Dbase.all #change Dbase.all to final hidden version fdb.all or left index as null with no code
  end
  
  def upload
    begin
      $filepath1 = params[:file1].path
      puts "path1 = #{$filepath1}"
      #content1 = File.read(params[:file1].tempfile)
      #puts "%%%%%%%%%%%%%%%%CONTENT!%%%%%%%%%%%%%%%%%%%%% = #{content1}"
      $filepath2 = params[:file2].path
      puts "path2 = #{$filepath2}"
      $threshold = params[:threshold]
      puts "$threshold=  #{$threshold}"
      #risky = Hash.new # hash of attribute values which contain privacy risk, key is set of combination of attr values, value is count
      #risky = apriori_algorithm($filepath1, $threshold)
      #puts risky
      redirect_to view_path
      #redirect_to threshold_path #, notice: 'Database uploaded successfully.' # redirect to view_url(final hidden version fdb.all)
    rescue
      redirect_to root_url, notice: 'Invalid CSV file format.' # redirect to root_url showing error
    end
  end


  def view
    if params['reload'] == '0'
      return
    end

    #AUTOMATIC LINKAGE
    file_paths = Array[$filepath1, $filepath2]
    $cluster = automatic_linkage(file_paths)

    $message = ""
    puts "@@@@@@@@@@@@@@@@@@@@@@@PATH = #{$filepath1}"
    #first_line = File.foreach($filepath1).first
    #$column_names = first_line.strip.split(',')
    #$num_cols = $column_names.size

    
    
    row = 0
    #Now instaed of reading from file, read from $cluster hash
    
    $cluster.each do |key, value|
       puts "key = #{key}"
       puts "value = #{value}\n"
       if value.size >= 2
            for i in 0..1
              puts "value#{i}= #{value[i]}\n";
              if i == 0
                  values_one = value[i]
              else
                  values_two = value[i]
              end
              for j in 0..value[i].size-1
                  puts "val = #{value[i][j]}\n"
              end 
            end
            for col in 0..$num_cols - 1
              $values_first[row][col] = values_one[col]
              $values_second[row][col] = values_two[col]
              $values_revealed[row][col] = "partial"
              partial_first, partial_second = get_edit_distance(values_one[col], values_two[col])
              $values_first_shown[row][col] = partial_first
              $values_second_shown[row][col] = partial_second
            end
            row += 1
        end 
    end 
    
=begin   
    File.foreach($filepath1).drop(1).each_slice(2) do |line|
      values_one = line[0].strip.split(',')
      values_two = line[1].strip.split(',')
      for col in 0..$num_cols - 1
        $values_first[row][col] = values_one[col]
        $values_second[row][col] = values_two[col]
        $values_revealed[row][col] = "partial"
        partial_first, partial_second = get_edit_distance(values_one[col], values_two[col])
        $values_first_shown[row][col] = partial_first
        $values_second_shown[row][col] = partial_second
      end
      row += 1
    end
=end

    $num_rows = row

    for row in 0..$num_rows - 1
      $is_match[row] = false
    end

    $all_rare_sets = apriori_algorithm($cluster, $threshold)
    $privacy_budget = 100.0
  end





  def get_partial(first_val, second_val)
    return get_edit_distance(first_val, second_val)
  end






  def update
    row = params['row'].to_i
    col = params['column'].to_i
    #response = Hash.new{|h, k| h[k] = []}
    status = "ok"
    $message = "Values updated."

    if $values_revealed[row][col] == "partial"
      if $values_first[row][col] == $values_second[row][col]
        status = "error"
        $message = "The value is same and therefore cannot be revealed."
      else
        $values_first_shown[row][col] = $values_first[row][col]
        $values_second_shown[row][col] = $values_second[row][col]
        $values_revealed[row][col] = "full"

        # Make a set of all revealed values in this row.
        revealed_set = Set.new
        for this_col in 0..$num_cols - 1
          if $values_revealed[row][this_col] == "full"
            revealed_set.add($values_first[row][this_col])
          end
        end

        # Check all the rare sets
        $all_rare_sets.each do |set, count|
          # If the rare set is a subset of the revealed set for this row and the rare set also contained the newly
          # revealed value, decrease the privacy budget.
          if set.subset? revealed_set and set.include? $values_first[row][col]
            puts $all_rare_sets.size * count
            $privacy_budget = $privacy_budget - 100.0/($all_rare_sets.size*count)
          end
        end


        # Do everything again for the second row.
        # Make a set of all revealed values in this row.
        revealed_set = Set.new
        for this_col in 0..$num_cols - 1
          if $values_revealed[row][this_col] == "full"
            revealed_set.add($values_second[row][this_col])
          end
        end

        # Check all the rare sets
        $all_rare_sets.each do |set, count|
          # If the rare set is a subset of the revealed set for this row and the rare set also contained the newly
          # revealed value, decrease the privacy budget.
          if set.subset? revealed_set and set.include? $values_second[row][col]
            puts $all_rare_sets.size * count
            $privacy_budget = $privacy_budget - 100.0/($all_rare_sets.size*count)
          end
        end
      end

    else
      status = "error"
      $message = "This value is already fully revealed."
    end

    render :json => {
               :status => status,
               :message => $message
           }
  end





  def update_match
    row = params['row'].to_i
    already_matched = params['matched']
    if already_matched == "true"
      $is_match[row] = false
    else
      $is_match[row] = true
    end
    render :plain => "OK"
  end


  def go_next
    if $start_index + $gap < $num_rows
      $start_index = $start_index + $gap
    end
    render :plain => "OK"
  end

  def go_prev
    if $start_index - $gap >= 0
      $start_index = $start_index - $gap
    end
    render :plain => "OK"
  end
end