class GoalsController < ApplicationController
  include DayScoped

  before_action :set_goal, only: [ :edit, :update, :destroy, :complete, :uncomplete, :start_timer, :stop_timer, :cancel_timer, :focus, :schedule ]
  before_action -> { @sheet = true }, only: [ :new, :create, :edit, :update ]
  before_action -> { @fullscreen = true }, only: [ :focus ]

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
    completion = @goal.goal_completions.find_or_create_by!(occurred_on: occurred_on) do |c|
      c.completed_at = Time.current
      c.points_awarded = Setting.instance.points_per_goal
    end

    toast = "+#{completion.points_awarded} points" if completion.previously_new_record?
    respond_to_toggle(occurred_on, toast: toast)
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

    toast = nil
    if @goal.timer_running?
      duration_seconds = (Time.current - @goal.current_timer_started_at).round
      completion = @goal.goal_completions.find_or_initialize_by(occurred_on: occurred_on)
      completion.points_awarded = Setting.instance.points_per_goal if completion.new_record?
      completion.started_at = @goal.current_timer_started_at
      completion.duration_seconds = duration_seconds
      completion.completed_at = Time.current
      completion.save!
      @goal.update!(current_timer_started_at: nil)
      # The flash only reaches the user via format.html (the focus page
      # opts out of Turbo) — guarded so it doesn't leak into the session and
      # surface later when this is really the checklist's turbo_stream path.
      flash[:notice] = "+#{completion.points_awarded} points · #{duration_seconds / 60} min" unless request.format.symbol == :turbo_stream
      toast = "+#{completion.points_awarded} points"
    end

    respond_to_toggle(occurred_on, toast: toast)
  end

  # Abandons an in-progress timer without completing the goal or recording
  # any duration ("Fermer sans enregistrer" on the focus screen).
  def cancel_timer
    @goal.update!(current_timer_started_at: nil)
    occurred_on = Date.parse(params[:occurred_on])
    respond_to_toggle(occurred_on)
  end

  # Full-screen timer view. Ensures the timer is running (starting it if
  # this is how the user is beginning the goal) before rendering.
  def focus
    @occurred_on = Date.parse(params[:occurred_on])
    @goal.update!(current_timer_started_at: Time.current) unless @goal.timer_running?
  end

  # Assigns (or clears, if hour is blank) this goal's slot in the day
  # ribbon — a UI-only placement, not tied to any particular occurrence.
  def schedule
    date = Date.parse(params[:date])
    @goal.update!(scheduled_hour: params[:hour].presence)
    load_day(date)
    hour_label = "%02d:00" % @goal.scheduled_hour if @goal.scheduled_hour.present?

    respond_to do |resp_format|
      resp_format.html { redirect_to day_path(date: date) }
      resp_format.turbo_stream do
        reference_date = @goal.occurrence_date(date)
        streams = [
          turbo_stream.replace("day-ribbon", partial: "days/ribbon"),
          # The checklist row (rendered separately from the ribbon) shows its
          # own "HH:00" badge once scheduled — without this it stays stale,
          # showing no time, until the next full page load.
          turbo_stream.replace(
            helpers.dom_id(@goal, reference_date.to_s),
            partial: "goals/goal",
            locals: { goal: @goal, reference_date: reference_date, completion: @completions[[ @goal.id, reference_date ]] }
          )
        ]
        streams << turbo_stream.append("toasts", partial: "shared/toast", locals: { message: "Casé à #{hour_label}" }) if hour_label
        render turbo_stream: streams
      end
    end
  end

  private

  def set_goal
    @goal = Goal.find(params[:id])
  end

  # The form always submits all four type-specific fields (the irrelevant
  # ones are only hidden via CSS, not removed from the DOM), so the fields
  # that don't apply to the chosen type are cleared here rather than trusted
  # from the client.
  # scheduled_hour is deliberately not permitted here — it's only ever set
  # via #schedule, so editing a goal's title etc. can't accidentally clobber
  # its planned time slot.
  def goal_params
    permitted = params.require(:goal).permit(:title, :description, :frequency, :recurring, :scheduled_on, :active_from, :timed)
    if ActiveModel::Type::Boolean.new.cast(permitted[:recurring])
      permitted[:scheduled_on] = nil
    else
      permitted[:frequency] = nil
      permitted[:active_from] = nil
    end
    permitted
  end

  # The focus page isn't reachable via Turbo Frame/Stream (it's a real
  # full-screen page, not an in-place update target), so its "Terminé" /
  # "Fermer sans enregistrer" forms opt out of Turbo (turbo: false) and rely
  # on this explicit param — request.referer alone would just point back at
  # the focus page itself.
  def redirect_target
    params[:return_to].presence || request.referer || root_path
  end

  def respond_to_toggle(occurred_on, toast: nil)
    respond_to do |format|
      format.html { redirect_to redirect_target }
      format.turbo_stream do
        load_gamification_summary # points/streak may have changed, refresh after the toggle
        completion = @goal.goal_completions.find_by(occurred_on: occurred_on)
        streams = [
          turbo_stream.replace(
            helpers.dom_id(@goal, occurred_on.to_s),
            partial: "goals/goal",
            locals: { goal: @goal, reference_date: occurred_on, completion: completion }
          ),
          turbo_stream.replace("gamification-summary", partial: "shared/points_pill")
        ]
        # The day page's progress ring also needs updating — but only safe to
        # recompute from `occurred_on` for a daily/one-off goal, where it's
        # exactly the day being viewed. A weekly goal's occurred_on is its
        # week's Monday, which could be a different day than whatever's
        # currently on screen, so it's left stale until the next navigation
        # rather than risk showing the wrong day's numbers.
        if @goal.daily?
          load_day(occurred_on)
          @previous_date = occurred_on - 1
          @next_date = occurred_on + 1
          streams << turbo_stream.replace("progress-ring", partial: "days/progress_ring")
        end
        streams << turbo_stream.append("toasts", partial: "shared/toast", locals: { message: toast }) if toast
        render turbo_stream: streams
      end
    end
  end
end
