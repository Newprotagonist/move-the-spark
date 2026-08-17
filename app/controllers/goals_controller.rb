class GoalsController < ApplicationController
  before_action :set_goal, only: [ :edit, :update, :destroy, :complete, :uncomplete, :start_timer, :stop_timer ]
  before_action -> { @sheet = true }, only: [ :new, :create, :edit, :update ]

  def new
    @goal = Goal.new(
      recurring: params[:recurring] == "true",
      frequency: params[:frequency].presence || "daily",
      scheduled_on: params[:scheduled_on].presence && Date.parse(params[:scheduled_on])
    )
  end

  def create
    @goal = Goal.new(goal_params)
    if @goal.save
      # Not referer-based: the referer for a create POST is the "new" form
      # page itself, which would just bounce back to an empty form.
      redirect_to(@goal.recurring? ? root_path : day_path(date: @goal.scheduled_on), notice: "Objectif créé.")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @goal.update(goal_params)
      redirect_to redirect_target, notice: "Objectif mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @goal.destroy
    redirect_to redirect_target, notice: "Objectif supprimé."
  end

  def complete
    occurred_on = Date.parse(params[:occurred_on])
    @goal.goal_completions.find_or_create_by!(occurred_on: occurred_on) do |completion|
      completion.completed_at = Time.current
      completion.points_awarded = Setting.instance.points_per_goal
    end

    respond_to_toggle(occurred_on)
  end

  def uncomplete
    occurred_on = Date.parse(params[:occurred_on])
    @goal.goal_completions.find_by(occurred_on: occurred_on)&.destroy

    respond_to_toggle(occurred_on)
  end

  # Starting the timer only records when it started; it does not complete
  # the goal by itself (per spec, no manual estimate — only the real
  # elapsed time, captured once the timer is stopped).
  def start_timer
    occurred_on = Date.parse(params[:occurred_on])
    @goal.update!(current_timer_started_at: Time.current) unless @goal.timer_running?

    respond_to_toggle(occurred_on)
  end

  # Stopping the timer both logs the elapsed duration and completes the
  # goal for this occurrence (spec: duration is only ever recorded "each
  # time a timed goal is realized").
  def stop_timer
    occurred_on = Date.parse(params[:occurred_on])

    if @goal.timer_running?
      duration_seconds = (Time.current - @goal.current_timer_started_at).round
      completion = @goal.goal_completions.find_or_initialize_by(occurred_on: occurred_on)
      completion.points_awarded = Setting.instance.points_per_goal if completion.new_record?
      completion.started_at = @goal.current_timer_started_at
      completion.duration_seconds = duration_seconds
      completion.completed_at = Time.current
      completion.save!
      @goal.update!(current_timer_started_at: nil)
    end

    respond_to_toggle(occurred_on)
  end

  private

  def set_goal
    @goal = Goal.find(params[:id])
  end

  # The form always submits all four type-specific fields (the irrelevant
  # ones are only hidden via CSS, not removed from the DOM), so the fields
  # that don't apply to the chosen type are cleared here rather than trusted
  # from the client.
  def goal_params
    permitted = params.require(:goal).permit(:title, :description, :frequency, :recurring, :scheduled_on, :active_from)
    if ActiveModel::Type::Boolean.new.cast(permitted[:recurring])
      permitted[:scheduled_on] = nil
    else
      permitted[:frequency] = nil
      permitted[:active_from] = nil
    end
    permitted
  end

  def redirect_target
    request.referer || root_path
  end

  def respond_to_toggle(occurred_on)
    respond_to do |format|
      format.html { redirect_to redirect_target }
      format.turbo_stream do
        load_gamification_summary # points/streak may have changed, refresh after the toggle
        completion = @goal.goal_completions.find_by(occurred_on: occurred_on)
        render turbo_stream: [
          turbo_stream.replace(
            helpers.dom_id(@goal, occurred_on.to_s),
            partial: "goals/goal",
            locals: { goal: @goal, reference_date: occurred_on, completion: completion }
          ),
          turbo_stream.replace("gamification-summary", partial: "shared/points_pill")
        ]
      end
    end
  end
end
