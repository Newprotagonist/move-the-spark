class DaysController < ApplicationController
  include DayScoped

  def show
    date = parse_date(params[:date]) || Date.current
    load_day(date)
    @previous_date = @date - 1
    @next_date = @date + 1

    @today_progress = StreakCalculator.new(unit: :day, reference_date: @date).current_period_progress if @date == Date.current
  end
end
