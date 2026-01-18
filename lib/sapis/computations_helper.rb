=begin

<computations_helper.rb> - Part of Sav's APIs.
Copyright (C) 2011 Saverio Miroddi

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=end

module ComputationsHelper
  # Covnerts to incremental values.
  #
  # Modifies the original data.
  #
  # Example:
  #   [ 1, 0, -1, 1 ]
  # becomes:
  #   [ 1, 1, 0,  1 ]
  #
  def self.convert_to_incremental_values!(source_values)
    current_sum = 0

    source_values.map! do |value|
      if value
        current_sum += value
        current_sum
      end
    end
  end

  SMOOTHING_DATA = {
    5 => [35.0,  [-3, 12, 17, 12, -3]],
    7 => [21.0,  [-2, 3, 6, 7, 6, 3, -2]],
    9 => [231.0, [-21, 14, 39, 54, 59, 54, 39, 14, -21]],
  }

  # Reference: http://stackoverflow.com/questions/4388911/how-can-i-draw-smoothed-rounded-curved-line-graphs-c
  #
  # Optimized for readability :-)
  #
  def self.smooth_line!(values, coefficients_number)
    h, coefficients = SMOOTHING_DATA[coefficients_number] || raise('Wrong number of coefficients')

    raise "Smoothing needs at least #{coefficients.size} values" if values.compact.size < coefficients.size

    buffer_middle_position = (coefficients.size + 1) / 2 - 1        # 0-based

    non_empty_positions = []
    original_values     = values.clone

    # The complexity is caused by the presence of nil values.
    # We cycle the array, and fill the buffer with the position of each non-null value encountered.
    # When the buffer is ready, we compute the smoothed value and set it, and remove the first entry
    # from the buffer.
    #
    values.each_with_index do |value, current_position|
      non_empty_positions << current_position if value

      next if non_empty_positions.size < coefficients.size

      buffer             = non_empty_positions.map { |non_empty_position| original_values[non_empty_position] }
      modifying_position = non_empty_positions[buffer_middle_position]

      values[modifying_position] = compute_smoothed_point(buffer, coefficients, h)

      non_empty_positions.shift
    end

    nil
  end

  private

  def self.compute_smoothed_point(buffer, coefficients, h)
    sum = buffer.zip(coefficients).inject(0) do |current_sum, (value, coefficient)|
      current_sum + value * coefficient
    end

    sum / h
  end
end
