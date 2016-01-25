class PpirlController < ApplicationController
  include PpirlHelper
  $file_path = "/Users/ankurgupta/Desktop/job/test_data.txt"
  $values_first = Hash.new{|h, k| h[k] = []}
  $values_second = Hash.new{|h, k| h[k] = []}
  $values_revealed = Hash.new{|h, k| h[k] = []}
  $values_first_shown = Hash.new{|h, k| h[k] = []}
  $values_second_shown = Hash.new{|h, k| h[k] = []}
  $is_match = Array.new

  $num_rows = 0
  $num_cols = 0
  $column_names = Array.new

  $start_index = 0
  $gap = 5

  def index
    if params['reload'] == '0'
      return
    end

    for row in 0..$num_rows - 1
      $is_match[row] = false
    end

    $message = ""
    file_path = $file_path
    first_line = File.foreach(file_path).first
    $column_names = first_line.strip.split(',')
    $num_cols = $column_names.size

    row = 0
    File.foreach(file_path).drop(1).each_slice(2) do |line|
      values_one = line[0].strip.split(',')
      values_two = line[1].strip.split(',')
      for col in 0..$num_cols - 1
        $values_first[row][col] = values_one[col]
        $values_second[row][col] = values_two[col]
        $values_revealed[row][col] = "no"
        if values_one[col] == values_two[col]
          $values_first_shown[row][col] = "SAME"
          $values_second_shown[row][col] = "SAME"
        else
          $values_first_shown[row][col] = "DIFF"
          $values_second_shown[row][col] = "DIFF"
        end
      end
      row += 1
    end

    $num_rows = row
  end





  def get_partial(first_val, second_val)
    return get_edit_distance(first_val, second_val)
  end






  def update
    row = params['row'].to_i
    col = params['column'].to_i
    response = Hash.new{|h, k| h[k] = []}
    status = "ok"
    $message = "Values updated."

    if $values_first_shown[row][col] == "SAME"
      status = "error"
      $message = "The value is same and therefore cannot be revealed."
    elsif $values_revealed[row][col] == "no"
      val_first, val_second = get_partial($values_first[row][col], $values_second[row][col])
      $values_first_shown[row][col] = val_first
      $values_second_shown[row][col] = val_second
      $values_revealed[row][col] = "partial"
    elsif $values_revealed[row][col] == "partial"
      $values_first_shown[row][col] = $values_first[row][col]
      $values_second_shown[row][col] = $values_second[row][col]
      $values_revealed[row][col] = "full"
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
