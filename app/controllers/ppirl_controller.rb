require 'set'
require 'open-uri'
require 'csv'

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
  $cluster = Hash.new{|h, k| h[k] = []} # hash for storing the connected components/clusters
  $cluster_num = Hash.new{|h, k| h[k] = []} # hash for storing the cluster number for every row shown in final output table
  $is_match = Array.new
  $budget_first = Hash.new{|h, k| h[k] = []} # hash for storing privacy budget for first row
  $budget_second = Hash.new{|h, k| h[k] = []} # hash for storing privacy budget for second row

  $rows_arr = [0,0] # To count total number of rows in DB1 and DB2
  $duplicates = 0 # To count number of entities resolved automatically
  $totaldb = Array.new # array for storing the tuples from both DB
  $totaldb1 = Array.new # array for storing the tuples from DB1
  $totaldb2 = Array.new # array for storing the tuples from DB2
  
  $num_rows = 0 # final uncertain rows
  $num_cols = 0 # final uncertain col
  $column_names = Array.new

  $start_index = 0
  $gap = 9
 # $first_line
  #$threshold = 3
  $all_rare_sets = Hash.new # key=set, value=count in db
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
    
    if($totaldb1.size > $totaldb1.uniq.size)
      $autolinked1 = ($totaldb1.size - $totaldb1.uniq!.size)
    else
      $autolinked1 = 0
    end
    
    if($totaldb2.size > $totaldb2.uniq.size)
      $autolinked2 = ($totaldb2.size - $totaldb2.uniq!.size)
    else
      $autolinked2 = 0
    end
    
    if($totaldb.size > $totaldb.uniq.size)
      $autolinked = $autolinked1 + $autolinked2 + ($totaldb.size - $totaldb.uniq!.size)
    else
      $autolinked = $autolinked1 + $autolinked2 + 0
    end
    
    $all_rare_sets = apriori_algorithm($totaldb, $threshold)
    $privacy_budget = 100.0
    
    row = 0 # counting the number of rows to be shown in output table
    cluster_n = 1 # counting the cluster number for all rows
    #Now instead of reading from file, read from $cluster hash
    
    $cluster.each do |key, value|
        #puts "key = #{key}"
        #puts "value = #{value}\n"
        values_one = value[0]
        for i in 1..value.size-1
          #puts "value#{i}= #{value[i]}\n"
          values_two = value[i]
          for col in 0..$num_cols - 1
              count_first = ""
              count_second = ""
              $values_first[row][col] = values_one[col]
              $values_second[row][col] = values_two[col]
              $values_revealed[row][col] = "partial"
              partial_first, partial_second = get_edit_distance(values_one[col], values_two[col])
              $all_rare_sets.each do |k, v|
                  if k.include?$values_first[row][col]
                      puts "$values_first[row][col]=  #{$values_first[row][col]} "
                      count_first = v.to_s
                  end
                  if k.include?$values_second[row][col]
                      count_second = v.to_s
                  end
              end
              if(count_first != "" && partial_first != "Miss")
                  $values_first_shown[row][col] = partial_first + ":" + count_first
              else
                  $values_first_shown[row][col] = partial_first
              end
              if(count_second != "" && partial_second != "")
                  $values_second_shown[row][col] = partial_second + ":" + count_second
              else
                  $values_second_shown[row][col] = partial_second
              end
          end
          $cluster_num[row] = cluster_n
          row += 1
        end
        cluster_n += 1
    end 
    
    $num_rows = row

    for row in 0..$num_rows - 1
      $is_match[row] = "false"
    end

    #$all_rare_sets = apriori_algorithm($cluster, $threshold)
    #$privacy_budget = 100.0
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
      if $values_first_shown[row][col] == "Miss" || $values_second_shown[row][col] == "Miss"
        status = "error"
        $message = "The value is missing and therefore cannot be revealed."
      elsif $values_first[row][col] == $values_second[row][col]
        status = "error"
        $message = "The value is same and therefore cannot be revealed."
      else
        if($values_first_shown[row][col].include?':')
          freq = $values_first_shown[row][col].split(':')[1]
          $values_first_shown[row][col] = $values_first[row][col] + ":" + freq
        else
          $values_first_shown[row][col] = $values_first[row][col]
        end
        
        if($values_second_shown[row][col].include?':')
          freq = $values_second_shown[row][col].split(':')[1]
          $values_second_shown[row][col] = $values_second[row][col] + ":" + freq
        else
          $values_second_shown[row][col] = $values_second[row][col]
        end
        
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
            #puts $all_rare_sets.size * count
            # In privacy risk calculation, we are considering those attr values also which do not have privacy risk like the one which cannot be disclosed because they are similar to their
            # corresponding pair value, since they are in rare set we are not excluding them from below formula. Effectively rare set contains all the attr values which have
            # anonymity-set size less than k irrespective if they are clickable or disclosable on gui screen
            $privacy_budget = $privacy_budget - 100.0/($all_rare_sets.size*count)
            #$budget_first = 100.0/($all_rare_sets.size*count)
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
            #puts $all_rare_sets.size * count
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
      $is_match[row] = "false"
    else
      $is_match[row] = "true"
    end
    render :plain => "OK"
  end


  def go_next
    if $start_index + 1 + $gap < $num_rows
      $start_index = $start_index + 1 + $gap
    end
    render :plain => "OK"
  end

  def go_prev
    if $start_index - 1 - $gap >= 0
      $start_index = $start_index - 1 - $gap
    end
    render :plain => "OK"
  end

  def finish
    CSV.open("/home/ubuntu/workspace/Linkage.csv", "w") do |csv|
      for row in 0..$num_rows - 1
          linkage = $is_match[row]
          $values_first_shown[row].pop
          $values_second_shown[row].pop
          #puts "value = #{$values_first[row]}"
          $values_first_shown[row] << linkage
          $values_second_shown[row] << linkage
          #puts "NEWvalue = #{$values_first[row]}"
          csv << $values_first_shown[row]
          csv << $values_second_shown[row]
          csv << ['\n']
      end
    end
    render :plain => "OK"
  end
  
end