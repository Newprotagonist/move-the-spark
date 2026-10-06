class GoalsController < ApplicationController
  include DayScoped

  before_action :set_goal, only: [ :edit, :update, :destroy, :complete, :uncomplete, :start_timer, :pause_timer, :resume_timer, :stop_timer, :cancel_timer, :archive, :unarchive, :focus, :history, :schedule ]
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

  # Stops a recurring goal from being due going forward without losing its
  # completion history (unlike #destroy, which cascades to GoalCompletion).
  def archive
    @goal.update!(archived_at: Time.current)
    redirect_to redirect_target, notice: "Objectif archivé."
  end

  def unarchive
    @goal.update!(archived_at: nil)
    redirect_to redirect_target, notice: "Objectif réactivé."
  end

  def archived
    @archived_goals = Goal.archived.ordered
  end

  def complete
    occurred_on = Date.parse(params[:occurred_on])
    streak_before = current_streak_for(@goal)
    completion = @goal.goal_completions.find_or_create_by!(occurred_on: occurred_on) do |c|
      c.completed_at = Time.current
      c.points_awarded = Setting.instance.points_per_goal
    end
    newly_completed = completion.previously_new_record?

    bonus = newly_completed ? award_streak_bonus!(completion, streak_before, current_streak_for(@goal)) : 0
    respond_to_toggle(occurred_on, completion: completion, newly_completed: newly_completed, bonus: bonus)
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

  # Freezes the running timer's elapsed time without losing it: the actual
  # duration recorded on #stop_timer is computed from current_timer_started_at,
  # so the pause itself has to be persisted (not just a paused JS interval) or
  # wall-clock time spent paused would leak into the recorded duration.
  def pause_timer
    @goal.update!(timer_paused_at: Time.current) if @goal.timer_running? && !@goal.timer_paused?
    redirect_to focus_goal_path(@goal, occurred_on: params[:occurred_on])
  end

  # Shifts current_timer_started_at forward by however long the timer was
  # paused, so elapsed-time math everywhere else (#stop_timer, the focus
  # view, the JS ticker) stays correct without needing a separate
  # accumulated-duration column.
  def resume_timer
    if @goal.timer_paused?
      @goal.update!(current_timer_started_at: @goal.current_timer_started_at + (Time.current - @goal.timer_paused_at),
                     timer_paused_at: nil)
    end
    redirect_to focus_goal_path(@goal, occurred_on: params[:occurred_on])
  end

  # Stopping the timer both logs the elapsed duration and completes the
  # goal for this occurrence (spec: duration is only ever recorded "each
  # time a timed goal is realized").
  def stop_timer
    occurred_on = Date.parse(params[:occurred_on])

    completion = nil
    newly_completed = false
    bonus = 0
    if @goal.timer_running?
      streak_before = current_streak_for(@goal)
      newly_completed = !@goal.goal_completions.exists?(occurred_on: occurred_on)
      # If stopped while paused (rather than resuming first), the elapsed
      # time is frozen as of the pause, not wall-clock time to now.
      stop_reference = @goal.timer_paused? ? @goal.timer_paused_at : Time.current
      duration_seconds = (stop_reference - @goal.current_timer_started_at).round
      completion = @goal.goal_completions.find_or_initialize_by(occurred_on: occurred_on)
      completion.points_awarded = Setting.instance.points_per_goal if newly_completed
      completion.started_at = @goal.current_timer_started_at
      completion.duration_seconds = duration_seconds
      completion.completed_at = Time.current
      completion.save!
      @goal.update!(current_timer_started_at: nil, timer_paused_at: nil)

      bonus = newly_completed ? award_streak_bonus!(completion, streak_before, current_streak_for(@goal)) : 0
      # The flash only reaches the user via format.html (the focus page
      # opts out of Turbo) — guarded so it doesn't leak into the session and
      # surface later when this is really the checklist's turbo_stream path.
      # The focus page never renders the celebration overlay (turbo_stream-
      # only, see #respond_to_toggle), so it always gets the plain toast
      # text here even on the day's last goal.
      flash[:notice] = "#{completion_toast(completion, bonus)} · #{duration_seconds / 60} min" unless request.format.symbol == :turbo_stream
    end

    respond_to_toggle(occurred_on, completion: completion, newly_completed: newly_completed, bonus: bonus)
  end

  # Abandons an in-progress timer without completing the goal or recording
  # any duration ("Fermer sans enregistrer" on the focus screen).
  def cancel_timer
    @goal.update!(current_timer_started_at: nil, timer_paused_at: nil)
    occurred_on = Date.parse(params[:occurred_on])
    respond_to_toggle(occurred_on)
  end

  # Full-screen timer view. Ensures the timer is running (starting it if
  # this is how the user is beginning the goal) before rendering.
  def focus
    @occurred_on = Date.parse(params[:occurred_on])
    @goal.update!(current_timer_started_at: Time.current) unless @goal.timer_running?
  end

  def history
    @history = GoalHistory.new(@goal)
    @occurrences = @history.occurrences
  end

  # Assigns (or clears, if hour is blank) this goal's slot in the day
  # ribbon — a UI-only placement, not tied to any particular occurrence.
  def schedule
    date = Date.parse(params[:date])
    @goal.update!(scheduled_hour: params[:hour].presence, scheduled_minute: params[:hour].presence ? params[:minute].presence || 0 : 0)
    load_day(date)
    hour_label = "%02d:%02d" % [ @goal.scheduled_hour, @goal.scheduled_minute ] if @goal.scheduled_hour.present?

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
  # scheduled_hour/scheduled_minute are deliberately not permitted here —
  # they're only ever set via #schedule, so editing a goal's title etc.
  # can't accidentally clobber its planned time slot.
  def goal_params
    permitted = params.require(:goal).permit(:title, :description, :frequency, :recurring, :scheduled_on, :active_from, :timed, :scheduled_weekday)
    if ActiveModel::Type::Boolean.new.cast(permitted[:recurring])
      permitted[:scheduled_on] = nil
      permitted[:scheduled_weekday] = nil unless permitted[:frequency] == "weekly"
    else
      permitted[:frequency] = nil
      permitted[:active_from] = nil
      permitted[:scheduled_weekday] = nil
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

  def current_streak_for(goal)
    StreakCalculator.new(unit: goal.weekly? ? :week : :day).current_streak
  end

  # Awards a bonus only when this completion is what actually grew the
  # user's real current streak (not merely "any goal was completed today")
  # — retroactively completing a past missed day counts too, as long as it
  # closes the gap and bumps the streak as of today.
  def award_streak_bonus!(completion, streak_before, streak_after)
    return 0 unless streak_after > streak_before

    bonus = [ streak_after, Setting.instance.streak_bonus_cap ].min
    completion.update!(points_awarded: completion.points_awarded + bonus) if bonus.positive?
    bonus
  end

  # Manual pluralization, not Rails' pluralize: it inflects using I18n.locale
  # (:fr here), and this app defines no French inflection rules, so it
  # silently returns the singular unchanged regardless of count. The rest of
  # the app already avoids it for the same reason (see profiles/show and
  # weeks/show's "jour<%= "s" if ... %>" pattern).
  def completion_toast(completion, bonus)
    base = "+#{completion.points_awarded} étincelle#{"s" if completion.points_awarded != 1}"
    bonus.positive? ? "#{base} (+#{bonus} flamme !)" : base
  end

  # Whether `occurred_on`'s completion is the one that leaves every daily
  # goal due today fully done — the trigger for the celebration overlay.
  # Weekly-goal completions never qualify (same @goal.daily? framing as the
  # ring/ribbon refresh below — a weekly goal's occurred_on isn't "today" in
  # this sense), and neither does completing a past day's occurrence — the
  # celebration is about finishing *today*, not backfilling history. Guarded
  # to fire at most once per calendar day via Setting#last_celebrated_on
  # (same pattern DailyGoalReminderJob uses for its own once-a-day guard),
  # so unchecking and rechecking an already-finished day's last goal doesn't
  # celebrate twice.
  def celebrate_day_complete?(occurred_on)
    return false unless @goal.daily? && occurred_on == Date.current
    return false if Setting.instance.last_celebrated_on == Date.current

    due_today = Goal.due_on(occurred_on)
    completed_ids = GoalCompletion.where(goal_id: due_today.select(:id), occurred_on: occurred_on).pluck(:goal_id)
    due_today.all? { |goal| completed_ids.include?(goal.id) }
  end

  def respond_to_toggle(occurred_on, completion: nil, newly_completed: false, bonus: 0)
    respond_to do |format|
      format.html { redirect_to redirect_target }
      format.turbo_stream do
        load_gamification_summary # points/streak may have changed, refresh after the toggle
        current_completion = @goal.goal_completions.find_by(occurred_on: occurred_on)
        # The row's own buttons carry `plannable` as a request param so the
        # re-rendered row keeps whatever the page it came from intended
        # (defaults true) — otherwise a week-view row, always rendered with
        # plannable: false there, would flip back to true on any toggle and
        # show a "planning" clock icon with no planning controller in scope
        # to handle it on that page.
        plannable = params[:plannable] != "false"
        streams = [
          turbo_stream.replace(
            helpers.dom_id(@goal, occurred_on.to_s),
            partial: "goals/goal",
            locals: { goal: @goal, reference_date: occurred_on, completion: current_completion, plannable: plannable, bursting: newly_completed }
          ),
          turbo_stream.replace("gamification-summary", partial: "shared/points_pill")
        ]
        # The day page's progress ring and ribbon also need updating — but
        # only safe to recompute from `occurred_on` for a daily/one-off
        # goal, where it's exactly the day being viewed. A weekly goal's
        # occurred_on is its week's Monday, which could be a different day
        # than whatever's currently on screen, so both are left stale until
        # the next navigation rather than risk showing the wrong day's data
        # (this also covers the ribbon card for a goal that's both
        # completed here and separately scheduled into an hour slot).
        if @goal.daily?
          load_day(occurred_on)
          @previous_date = occurred_on - 1
          @next_date = occurred_on + 1
          streams << turbo_stream.replace("progress-ring", partial: "days/progress_ring")
          streams << turbo_stream.replace("day-ribbon", partial: "days/ribbon")
        end

        if newly_completed && celebrate_day_complete?(occurred_on)
          Setting.instance.update!(last_celebrated_on: Date.current)
          streams << turbo_stream.append("celebration-overlay", partial: "shared/celebration_overlay",
                                          locals: { bonus: bonus, streak: current_streak_for(@goal), total: Goal.due_on(occurred_on).size })
        elsif newly_completed
          streams << turbo_stream.append("toasts", partial: "shared/toast", locals: { message: completion_toast(completion, bonus) })
        end

        render turbo_stream: streams
      end
    end
  end
end
